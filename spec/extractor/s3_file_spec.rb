require 'remi_spec'
require 'aws-sdk'

describe Extractor::S3File do

  before do
    Aws.config[:s3] = {
      stub_responses: true
    }

    prefix = "the-best-prefix"
    @s3_file = Extractor::S3File.new(bucket: 'the-best-bucket', remote_path: "#{prefix}")
    @s3_file.s3_client.stub_responses(:list_objects, {
      contents: [
        { key: "#{prefix}/file1.csv" },
        { key: "#{prefix}/file2.csv" }
      ]
    })

  end

  it 'returns all entries' do
    expect(@s3_file.all_entries.map(&:name)).to eq ['file1.csv', 'file2.csv']
  end
end
