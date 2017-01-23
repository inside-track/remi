require_relative '../remi_spec'

describe Parser::CsvFile do

  let(:basic_file) { 'spec/fixtures/basic.csv' }
  let(:basic_dataframe) do
    Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B']
      }
    )
  end

  it 'converts a CSV into a dataframe' do
    csv = Parser::CsvFile.new
    expect(csv.parse(basic_file).to_a).to eq basic_dataframe.to_a
  end

  it 'adds filename when requested' do
    csv = Parser::CsvFile.new(
      filename_field: :from_file
    )

    expected_files = [Pathname.new(basic_file).to_s] * 2
    expect(csv.parse(basic_file)[:from_file].to_a).to eq expected_files
  end

  it 'preprocesses records when required' do
    csv = Parser::CsvFile.new(
      preprocessor: ->(line) { line.gsub(/\\"/,'""') }
    )

    bad_escape_file = 'spec/fixtures/unsupported_escape.csv'

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A'],
        column_b: ['value "1B"', 'value "2B"']
      }
    )
    expect(csv.parse(bad_escape_file).to_a).to eq expected_df.to_a
  end

  it 'accepts standard Ruby CSV options' do
    csv = Parser::CsvFile.new(
      preprocessor: ->(line) { line.gsub(/,/,'|') },
      csv_options: { col_sep: '|' }
    )

    expect(csv.parse(basic_file).to_a).to eq basic_dataframe.to_a
  end

  it 'combines multiple csv files into a single dataframe' do
    csv = Parser::CsvFile.new
    two_files = ['spec/fixtures/basic.csv', 'spec/fixtures/basic2.csv']

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A', 'value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B', nil, nil],
        column_c: [nil, nil, 'value 1C', 'value 2C']
      }
    )

    expect(csv.parse(two_files).to_a).to eq expected_df.to_a
  end
  it 'returns empty vectors if the csv contains headers only' do
    csv = Parser::CsvFile.new

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: [],
        column_b: []
      }
    )

    expect(csv.parse('spec/fixtures/empty.csv').to_h).to eq expected_df.to_h
  end
end

describe Encoder::CsvFile do
  let(:basic_dataframe) do
    Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B']
      }
    )
  end
  it 'creates a csv from a provided dataframe' do
    encoder = Encoder::CsvFile.new
    parser = Parser::CsvFile.new
    provided_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A', 'value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B', nil, nil],
        column_c: [nil, nil, 'value 1C', 'value 2C']
      }
    )
    expected_contents = "column_a,column_b,column_c\nvalue 1A,value 1B,\nvalue 2A,value 2B,\nvalue 1A,,value 1C\nvalue 2A,,value 2C\n"
    file_name = encoder.encode(provided_df)
    expect(File.read(file_name)).to eq expected_contents
  end
  it 'uses label headers when provided' do
    provided_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A', 'value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B', nil, nil],
        column_c: [nil, nil, 'value 1C', 'value 2C']
      }
    )
    expected_contents = "Column A,Column B,Column C\nvalue 1A,value 1B,\nvalue 2A,value 2B,\nvalue 1A,,value 1C\nvalue 2A,,value 2C\n"
    column_fields = Remi::Fields.new({
      :column_a => { label: 'Column A' },
      :column_b => { label: 'Column B' },
      :column_c => { label: 'Column C' }
    })
    encoder = Encoder::CsvFile.new(fields: column_fields)
    file_name = encoder.encode(provided_df)
    expect(File.read(file_name)).to eq expected_contents
  end
end

