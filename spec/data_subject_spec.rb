require_relative 'remi_spec'

# VERY SPARSE TESTING!  DO MORE!

describe DataSubject do

  describe 'enforcing types' do
    let(:dataframe) do
      Remi::DataFrame::Daru.new({ my_date: ['10/21/2015'] })
    end

    let(:data_subject) do
      DataSubject.new(fields: fields).tap { |ds| ds.df = dataframe }
    end

    let(:fields) do
      Fields.new({
        my_date:     { type: :date, in_format: '%m/%d/%Y' },
        other_date: { type: :date, in_format: '%m/%d/%Y' }
      })
    end

    it 'converts a date string to a date using an in_format' do
      data_subject.enforce_types
      expect(data_subject.df[:my_date].to_a).to eq [Date.new(2015, 10, 21)]
    end

    it 'does not do any conversion if the type is not specified' do
      fields[:my_date].delete(:type)
      data_subject.enforce_types
      expect(data_subject.df[:my_date].to_a).to eq ['10/21/2015']
    end

    it 'throws an error if the data does not conform to its type' do
      dataframe[:my_date].recode! { |v| '2015-10-21' }
      expect { data_subject.enforce_types }.to raise_error ArgumentError
    end

    it 'does not create new vectors during enforcement', wip: true do
      data_subject.enforce_types
      expect(dataframe.vectors.to_a).to eq [:my_date]
    end
  end
end
