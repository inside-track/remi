require_relative '../remi_spec'

describe DataSource::CsvFile do

  it "converts a CSV into a dataframe" do
    csv = Remi::DataSource::CsvFile.new(
      extractor: 'spec/fixtures/basic.csv'
    )

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B']
      }
    )
    expect(csv.df.to_a).to eq expected_df.to_a
  end

  it "adds filename when requested" do
    csv = Remi::DataSource::CsvFile.new(
      extractor: 'spec/fixtures/basic.csv',
      filename_field: :from_file
    )

    expect(csv.df[:from_file].to_a).to eq ['spec/fixtures/basic.csv'] * 2
  end

  it "preprocesses records when required" do
    csv = Remi::DataSource::CsvFile.new(
      extractor: 'spec/fixtures/unsupported_escape.csv',
      preprocessor: ->(line) { line.gsub(/\\"/,'""') }
    )

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A'],
        column_b: ['value "1B"', 'value "2B"']
      }
    )
    expect(csv.df.to_a).to eq expected_df.to_a
  end

  it "accepts standard Ruby CSV options" do
    csv = Remi::DataSource::CsvFile.new(
      extractor: 'spec/fixtures/basic.csv',
      preprocessor: ->(line) { line.gsub(/,/,'|') },
      csv_options: { col_sep: '|' }
    )

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B']
      }
    )
    expect(csv.df.to_a).to eq expected_df.to_a
  end

  # Do this when I retire the old LocalFile
  it "combines multiple csv files into a single dataframe", skip: 'TODO' do
    csv = Remi::DataSource::CsvFile.new(
      extractor: Remi::Extractor::LocalFile.new(
        remote_path: 'spec/fixtures',
        pattern: 'basic(|2)\.csv'
      )
    )

    expected_df = Remi::DataFrame::Daru.new(
      {
        column_a: ['value 1A', 'value 2A', 'value 1A', 'value 2A'],
        column_b: ['value 1B', 'value 2B', nil, nil],
        columb_c: [nil, nil, 'value 1C', 'value 2C']
      }
    )
    expect(csv.df.to_a).to eq expected_df.to_a
  end

end
