require_relative '../remi_spec'

describe DataSource::DataFrame do
  it "converts data into a dataframe" do
    source_dataframe = Remi::DataSource::DataFrame.new(
      fields: {
        :col1 => {},
        :col2 => {}
      },
      data: [
        ['11', '12'],
        ['21', '22'],
        ['31', '32']
      ]
    )

    expected_df = Remi::DataFrame::Daru.new(
      {
        col1: ['11', '21', '31'],
        col2: ['12', '22', '32']
      }
    )

    expect(source_dataframe.df).to be_a Remi::DataFrame
    expect(source_dataframe.df.to_a).to eq expected_df.to_a
  end
end
