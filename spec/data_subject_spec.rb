require_relative 'remi_spec'

describe DataSubject do
  let(:data_subject) { DataSubject.new(name: :awesome_subject) }

  context 'DSL' do
    let(:dsl_data_subject) do
      DataSubject.new(name: :awesome_dsl_subject) do
        fields :id => {}
        field_symbolizer :salesforce
      end
    end

    it 'defines the fields' do
      expect(dsl_data_subject.dsl_eval.fields).to eq({ :id => {} })
    end

    it 'sets the field symbolizer' do
      expect(dsl_data_subject.dsl_eval.field_symbolizer).to eq(Remi::FieldSymbolizers[:salesforce])
    end
  end

  it 'has a name' do
    expect(data_subject.name).to eq :awesome_subject
  end

  context '#df_type' do
    it 'returns the dataframe type' do
      expect(data_subject.df_type).to eq :daru
    end

    it 'sets the dataframe type' do
      expect { data_subject.df_type(:spark) }.to change {
        data_subject.df_type
      }.from(:daru).to(:spark)
    end
  end

  context '#fields' do
    it 'returns the field metadata' do
      expect(data_subject.fields).to be_a Remi::Fields
    end

    it 'sets the field metadata' do
      expect { data_subject.fields({ :id => {} }) }.to change {
        data_subject.fields
      }.from({}).to({ :id => {} })
    end
  end

  context '#field_symbolizer' do
    it 'returns the field symbolizer defined for this source' do
      expect(data_subject.field_symbolizer).to eq Remi::FieldSymbolizers[:standard]
    end

    it 'sets the field symbolizer' do
      data_subject.field_symbolizer :salesforce
      expect(data_subject.field_symbolizer).to eq Remi::FieldSymbolizers[:salesforce]
    end
  end

  context '#df' do
    it 'returns the dataframe associated with this subject' do
      expect(data_subject.df).to be_a Remi::DataFrame::Daru
    end
  end

  context '#df=' do
    let(:reassigned_df) { Daru::DataFrame.new({ a: [1955] }) }
    it 'reassigns the dataframe associated with this subject' do
      data_subject.df = reassigned_df
      expect(data_subject.df).to eq reassigned_df
    end

    it 'converts any non-remi dataframes to a remi dataframe' do
      data_subject.df = reassigned_df
      expect(data_subject.df).to be_a Remi::DataFrame::Daru
    end
  end

  context '#enforce_types' do
    let(:dataframe) { Remi::DataFrame::Daru.new({ my_date: ['10/21/2015'] }) }

    let(:fields) do
      {
        my_date:    { type: :date, in_format: '%m/%d/%Y' },
        other_date: { type: :date, in_format: '%m/%d/%Y' }
      }
    end

    before do
      data_subject.fields = fields
      data_subject.df = dataframe
    end

    it 'converts a date string to a date using an in_format' do
      data_subject.enforce_types
      expect(data_subject.df[:my_date].to_a).to eq [Date.new(2015, 10, 21)]
    end

    it 'converts types when explicitly specified' do
      data_subject.enforce_types(:date)
      expect(data_subject.df[:my_date].to_a).to eq [Date.new(2015, 10, 21)]
    end

    it 'does not do any conversion if the field has no type specified' do
      fields[:my_date].delete(:type)
      data_subject.enforce_types
      expect(data_subject.df[:my_date].to_a).to eq ['10/21/2015']
    end

    it 'does not do any conversion if field metadata does not match the selected enforcement type' do
      data_subject.enforce_types(:decimal)
      expect(data_subject.df[:my_date].to_a).to eq ['10/21/2015']
    end

    it 'throws an error if the data does not conform to its type' do
      dataframe[:my_date].recode! { |v| '2015-10-21' }
      expect { data_subject.enforce_types }.to raise_error ArgumentError
    end

    it 'does not create new vectors during enforcement' do
      data_subject.enforce_types
      expect(dataframe.vectors.to_a).to eq [:my_date]
    end
  end
end




describe DataSource do
  let(:data_source) { DataSource.new }

  let(:my_extractor) { double('my_extractor') }
  let(:my_extractor2) { double('my_extractor2') }
  let(:my_parser) { Remi::Parser.new }


  before do
    allow(my_extractor).to receive(:extract) .and_return 'result_1'
    allow(my_extractor2).to receive(:extract) .and_return 'result_2'
    allow(my_parser).to receive(:parse)
  end


  context 'DSL' do
    let(:dsl_data_source) do
      scoped_my_extractor = my_extractor
      scoped_my_extractor2 = my_extractor2
      scoped_my_parser = my_parser

      DataSource.new(name: :awesome_dsl_source) do
        extractor scoped_my_extractor
        extractor scoped_my_extractor2
        parser scoped_my_parser
      end
    end

    it 'adds extractors to the list of extractors' do
      expect(dsl_data_source.dsl_eval.extractors).to eq [my_extractor, my_extractor2]
    end

    it 'sets the parser' do
      expect(dsl_data_source.dsl_eval.parser).to eq my_parser
    end

    context '#df' do
      it 'executes the DSL commands that have been declared' do
        expect(my_extractor).to receive :extract
        expect(my_extractor2).to receive :extract
        expect(my_parser).to receive :parse
        dsl_data_source.df
      end
    end

    context '#field_symbolizer' do
      context 'field_symbolizer called before parser' do
        let(:before_parser) do
          scoped_my_parser = my_parser
          DataSource.new do
            field_symbolizer :salesforce
            parser scoped_my_parser
          end
        end

        it 'is used to set the field_symbolizer of the parser' do
          expect {
            before_parser.dsl_eval
          }.to change {
            my_parser.field_symbolizer
          }.from(Remi::FieldSymbolizers[:standard]).to(Remi::FieldSymbolizers[:salesforce])
        end
      end

      context 'field_symbolizer called after parser' do
        let(:after_parser) do
          scoped_my_parser = my_parser
          DataSource.new do
            parser scoped_my_parser
            field_symbolizer :salesforce
          end
        end

        it 'sets the field symbolizer of the parser for any parsers defined above' do
          expect {
            after_parser.dsl_eval
          }.to change {
            my_parser.field_symbolizer
          }.from(Remi::FieldSymbolizers[:standard]).to(Remi::FieldSymbolizers[:salesforce])
        end
      end
    end
  end

  context '#extractor' do
    before { data_source.extractor 'my_extractor' }

    it 'adds an extractor to the list of extractors' do
      expect(data_source.extractors).to eq ['my_extractor']
    end

    it 'allows for multiple extractors to be defined' do
      data_source.extractor 'my_extractor2'
      expect(data_source.extractors).to eq ['my_extractor', 'my_extractor2']
    end
  end

  context '#parser' do
    let(:my_parser) { Remi::Parser.new }

    context 'default parser' do
      it 'uses the None parser' do
        expect(data_source.parser).to be_a Parser::None
      end
    end

    context 'defining a parser' do
      before { data_source.parser my_parser }

      it 'sets the parser' do
        expect(data_source.parser).to eq my_parser
      end

      it 'only allows one parser to be defined' do
        my_new_parser = my_parser.clone
        data_source.parser my_new_parser
        expect(data_source.parser).to eq my_new_parser
      end

      it 'sets the context of parser' do
        data_source.parser my_parser
        expect(my_parser.context).to eq data_source
      end
    end
  end

  context 'with parsers and extractors defined' do
    before do
      data_source.extractor my_extractor
      data_source.extractor my_extractor2
      data_source.parser my_parser
    end

    context '#extract' do
      it 'extracts data from each extractor' do
        expect(my_extractor).to receive :extract
        expect(my_extractor2).to receive :extract
        data_source.extract
      end

      it 'collects the results of each extractor' do
        expect(data_source.extract).to eq ['result_1', 'result_2']
      end
    end

    context '#parse' do
      it 'uses the specified parser to parse the extracted data' do
        expect(my_parser).to receive(:parse) .with('result_1', 'result_2')
        data_source.parse
      end
    end

    context '#df' do
      context 'a dataframe has not already been defined' do

        it 'extracts' do
          expect(data_source).to receive :extract
          data_source.df
        end

        it 'parses' do
          expect(data_source).to receive :parse
          data_source.df
        end
      end

      context 'a dataframe has already been defined' do
        let(:dataframe) do
          df = double('df')
          allow(df).to receive :df_type
          df
        end
        before { data_source.df = dataframe }

        it 'simply returns the defined dataframe' do
          expect(data_source.df).to eq dataframe
        end

        it 'does not extract' do
          expect(data_source).not_to receive :extract
          data_source.df
        end

        it 'does not parse' do
          expect(data_source).not_to receive :parse
          data_source.df
        end
      end
    end

    context '#reset', skip: 'todo' do
      it 'clears the current dataframe' do
      end

      it 'allows the source data to be extracted and parsed again' do
      end
    end
  end
end


describe DataTarget do
  let(:data_target) { DataTarget.new }

  let(:my_encoder) { Remi::Encoder.new }
  let(:my_loader) { double('my_loader') }
  let(:my_loader2) { double('my_loader2') }

  before do
    allow(my_loader).to receive(:load)
    allow(my_loader2).to receive(:load)
    allow(my_encoder).to receive(:encode) .and_return 'encoded data'
  end

  context 'DSL' do
    let(:dsl_data_target) do
      scoped_my_encoder = my_encoder
      scoped_my_loader = my_loader
      scoped_my_loader2 = my_loader2

      DataTarget.new do
        encoder scoped_my_encoder
        loader scoped_my_loader
        loader scoped_my_loader2
      end
    end

    it 'adds loaders to the list of loaders' do
      expect(dsl_data_target.dsl_eval.loaders).to eq [my_loader, my_loader2]
    end

    it 'sets the encoder' do
      expect(dsl_data_target.dsl_eval.encoder).to eq my_encoder
    end

    context '#load' do
      it 'executes the DSL commands that have been declared' do
        df_double = double('df')
        allow(df_double).to receive(:size) .and_return(1)

        allow(dsl_data_target).to receive(:df) .and_return(df_double)

        expect(my_encoder).to receive :encode
        expect(my_loader).to receive :load
        expect(my_loader2).to receive :load
        dsl_data_target.load
      end
    end

    context '#field_symbolizer' do
      context 'field_symbolizer called before encoder' do
        let(:before_encoder) do
          scoped_my_encoder = my_encoder
          DataTarget.new do
            field_symbolizer :salesforce
            encoder scoped_my_encoder
          end
        end

        it 'is used to set the field_symbolizer of the encoder' do
          expect {
            before_encoder.dsl_eval
          }.to change {
            my_encoder.field_symbolizer
          }.from(Remi::FieldSymbolizers[:standard]).to(Remi::FieldSymbolizers[:salesforce])
        end
      end

      context 'field_symbolizer called after encoder' do
        let(:after_encoder) do
          scoped_my_encoder = my_encoder
          DataTarget.new do
            encoder scoped_my_encoder
            field_symbolizer :salesforce
          end
        end

        it 'sets the field symbolizer of the encoder for any encoders defined above' do
          expect {
            after_encoder.dsl_eval
          }.to change {
            my_encoder.field_symbolizer
          }.from(Remi::FieldSymbolizers[:standard]).to(Remi::FieldSymbolizers[:salesforce])
        end
      end
    end
  end

  context '#encoder' do
    let(:my_encoder) { Remi::Encoder.new }

    context 'default encoder' do
      it 'uses the None encoder' do
        expect(data_target.encoder).to be_a Encoder::None
      end
    end

    context 'defining an encoder' do
      before { data_target.encoder my_encoder }

      it 'sets the encoder' do
        expect(data_target.encoder).to eq my_encoder
      end

      it 'only allows one encoder to be defined' do
        my_new_encoder = my_encoder.clone
        data_target.encoder my_new_encoder
        expect(data_target.encoder).to eq my_new_encoder
      end

      it 'sets the context of encoder' do
        data_target.encoder my_encoder
        expect(my_encoder.context).to eq data_target
      end
    end
  end

  context '#loader' do
    before { data_target.loader 'my_loader' }

    it 'adds a loader to the list of loaders' do
      expect(data_target.loaders).to eq ['my_loader']
    end

    it 'allows for multiple loaders to be defined' do
      data_target.loader 'my_loader2'
      expect(data_target.loaders).to eq ['my_loader', 'my_loader2']
    end
  end

  context '#load' do
    before do
      data_target.encoder my_encoder
      data_target.loader my_loader
      data_target.loader my_loader2

      df_double = double('df')
      allow(df_double).to receive(:size) .and_return(1)

      allow(data_target).to receive(:df) .and_return(df_double)
    end

    it 'encodes data represented in the dataframe' do
      expect(my_encoder).to receive(:encode).once
      data_target.load
    end

    it 'passes encoded data to each of the loaders' do
      expect(my_loader).to receive(:load).with('encoded data')
      expect(my_loader2).to receive(:load).with('encoded data')
      data_target.load
    end

    it 'triggers a load for all of the loaders' do
      expect(my_loader).to receive(:load).once
      expect(my_loader2).to receive(:load).once
      data_target.load
    end

    it 'does not trigger loads twice' do
      expect(my_loader).to receive(:load).once
      expect(my_loader2).to receive(:load).once
      data_target.load
      data_target.load
    end

    context '#load!' do
      it 'triggers loads every time it is called' do
        expect(my_loader).to receive(:load).twice
        expect(my_loader2).to receive(:load).twice
        data_target.load!
        data_target.load!
      end
    end
  end

  context '#df=' do
    before do
      data_target.encoder my_encoder
      data_target.loader my_loader
      data_target.loader my_loader2

      allow(my_loader).to receive(:autoload) { false }
      allow(my_loader2).to receive(:autoload) { true }
    end

    it 'loads any loaders set to autoload' do
      expect(my_loader).not_to receive :load
      expect(my_loader2).to receive :load
      data_target.df = Remi::DataFrame::Daru.new([])
    end
  end
end
