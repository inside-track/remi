require_relative '../remi_spec'

describe Extractor::DataFrame do
  let(:extractor) { Extractor::DataFrame.new(data: data) }
  let(:data) { 'some_data' }

  context '#data' do
    it 'returns the raw data' do
      expect(extractor.extract.data).to eq data
    end
  end
end

describe Parser::DataFrame do
  let(:fields) do
    {
      brewer: { type: 'text' },
      style: { type: 'text' }
    }
  end
  let(:parser) { Parser::DataFrame.new(fields: fields) }
  let(:df_extract) { double('df_extract') }
  let(:data) {
    [
      [ 'Baerlic', 'IPA' ],
      [ 'Ex Novo', 'Red' ]
    ]
  }

  before do
    allow(df_extract).to receive(:data) { data }
  end

  it 'converts the data array into a dataframe' do
    expect(parser.parse df_extract).to be_a Remi::DataFrame::Daru
  end

  it 'converts the data array into the dataframe' do
    expected_df = Daru::DataFrame.new(
      :brewer => ['Baerlic', 'Ex Novo'],
      :style  => ['IPA', 'Red']
    )
    expect(parser.parse(df_extract).to_a).to eq expected_df.to_a
  end

end

describe Encoder::DataFrame, skip: 'todo' do
end

describe Loader::DataFrame, skip: 'todo' do
end
