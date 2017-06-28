require_relative 'all_jobs_shared'
require 'aws-sdk'

class S3FileTargetJob < Remi::Job
  target :some_file do
    encoder Remi::Encoder::CsvFile.new
    loader Remi::Loader::S3File.new(
      credentials: {
        aws_access_key_id: 'blort',
        aws_secret_access_key: 'blerg',
        region: 'us-west-2'
      },
      kms_opt: {
        ciphertext: 'blergity'
      },
      bucket: 'the-big-one',
      remote_path: "some_file_#{DateTime.current.strftime('%Y%m%d')}.csv"
    )
  end

  transform :main do
  end
end
