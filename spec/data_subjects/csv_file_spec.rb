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

  it 'converts a CSV into a dataframe', wip: true do
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

end
