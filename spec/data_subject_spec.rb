require_relative 'remi_spec'

describe DataSubject do
  let(:data_subject) { DataSubject.new(name: :awesome_subject) }

  context 'DSL' do
    let(:dsl_data_subject) do
      DataSubject.new(name: :awesome_dsl_subject) do
        fields :id => {}
        enforce_types
      end
    end

    it 'defines the fields' do
      dsl_data_subject.send(:dsl_eval)
      expect(dsl_data_subject.fields).to eq({ :id => {} })
    end

    it 'declares that types will be enforced' do
      expect(dsl_data_subject).to receive :enforce_types
      dsl_data_subject.send(:dsl_eval)
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
      data_subject.enforce_types
    end

    it 'converts a date string to a date using an in_format' do
      data_subject.enforce_types!
      expect(data_subject.df[:my_date].to_a).to eq [Date.new(2015, 10, 21)]
    end

    it 'converts types when explicitly specified' do
      data_subject.enforce_types(:date)
      data_subject.enforce_types!
      expect(data_subject.df[:my_date].to_a).to eq [Date.new(2015, 10, 21)]
    end

    it 'does not do any conversion if the field has no type specified' do
      fields[:my_date].delete(:type)
      data_subject.enforce_types!
      expect(data_subject.df[:my_date].to_a).to eq ['10/21/2015']
    end

    it 'does not do any conversion if field metadata does not match the selected enforcement type' do
      data_subject.enforce_types(:decimal)
      data_subject.enforce_types!
      expect(data_subject.df[:my_date].to_a).to eq ['10/21/2015']
    end

    it 'throws an error if the data does not conform to its type' do
      dataframe[:my_date].recode! { |v| '2015-10-21' }
      expect { data_subject.enforce_types! }.to raise_error ArgumentError
    end

    it 'does not create new vectors during enforcement' do
      data_subject.enforce_types!
      expect(dataframe.vectors.to_a).to eq [:my_date]
    end
  end
end




describe DataSource do
  let(:data_source) { DataSource.new }

  let(:my_extractor) { double('my_extractor') }
  let(:my_extractor2) { double('my_extractor2') }
  let(:my_parser) { double('my_parser') }

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
        enforce_types
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
        expect(dsl_data_source).to receive :enforce_types!
        dsl_data_source.df
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
    before { data_source.parser 'my_parser' }

    it 'sets the parser' do
      expect(data_source.parser).to eq 'my_parser'
    end

    it 'only allows one parser to be defined' do
      data_source.parser 'my_new_parser'
      expect(data_source.parser).to eq 'my_new_parser'
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
        expect(my_parser).to receive(:parse) .with(['result_1', 'result_2'])
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

        it 'enforces types' do
          expect(data_source).to receive :enforce_types!
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

        it 'does not enforce types' do
          expect(data_source).not_to receive :extract!
          data_source.df
        end
      end
    end
  end
end


describe DataTarget do
  let(:data_target) { DataTarget.new }
  let(:my_loader) { double('my_loader') }
  let(:my_loader2) { double('my_loader2') }

  context 'DSL' do
    let(:dsl_data_target) do
      scoped_my_loader = my_loader
      scoped_my_loader2 = my_loader2

      DataTarget.new do
        loader scoped_my_loader
        loader scoped_my_loader2
      end
    end

    it 'adds loaders to the list of loaders' do
    end

    context '#load' do
      it 'loads all of the targets' do
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

  context '#load', wip: true  do
    before do
      data_target.loader my_loader
      data_target.loader my_loader2

      df_double = double('df')
      allow(df_double).to receive(:size) .and_return(1)

      allow(data_target).to receive(:df) .and_return(df_double)
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
end
