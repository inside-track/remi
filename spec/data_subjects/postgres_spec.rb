require_relative '../remi_spec'

describe Extractor::Postgres do
  let(:extractor) { Extractor::Postgres.new(credentials: {}, query: 'some_query') }
  let(:pg_conn) { double('pg_conn') }
  let(:data) { 'some postgres data' }

  before do
    allow(pg_conn).to receive(:exec) { data }
    allow(extractor).to receive(:connection) { pg_conn }
  end

  context '#data' do
    it 'returns extracted data' do
      expect(extractor.extract.data).to eq data
    end
  end
end


describe Parser::Postgres do
  let(:parser) { Parser::Postgres.new }
  let(:pg_extract) { double('pg_extract') }
  let(:data) do
    [
      { 'brewer' => 'Baerlic', 'style' => 'IPA', 'quantity' => 5 },
      { 'brewer' => 'Ex Novo', 'style' => 'Red', 'quantity' => 3 }
    ]
  end

  before do
    allow(pg_extract).to receive(:data) { data }
  end

  it 'converts postgres response data into a dataframe' do
    expect(parser.parse pg_extract).to be_a Remi::DataFrame::Daru
  end

  it 'converted data into the correct dataframe' do
    expected_df = Daru::DataFrame.new(
      :brewer => ['Baerlic', 'Ex Novo'],
      :style  => ['IPA', 'Red'],
      :quantity => [5, 3]
    )
    expect(parser.parse(pg_extract).to_a).to eq expected_df.to_a
  end
end


describe Encoder::Postgres do
  let(:fields) do
    {
      brewer: { type: 'text' },
      style: { type: 'text' },
      quantity: { type: 'integer' }
    }
  end
  let(:encoder) { Encoder::Postgres.new(fields: fields) }
  let(:dataframe) do
    expected_df = Daru::DataFrame.new(
      :brewer => ['Baerlic', 'Ex Novo'],
      :style  => ['IPA', 'Red'],
      :quantity => [5, 3]
    )
  end

  it 'converts the dataframe into an array of strings to be used by the loader' do
    expect(encoder.encode(dataframe).values).to eq [
      "Baerlic\tIPA\t5",
      "Ex Novo\tRed\t3"
    ]
  end

  it 'builds the field ddl' do
    expect(encoder.encode(dataframe).ddl_fields).to eq 'brewer text, style text, quantity integer'
  end
end

describe Loader::Postgres, skip: 'todo' do
end
