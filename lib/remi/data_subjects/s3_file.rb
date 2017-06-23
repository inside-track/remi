module Remi

  module DataSubject::S3File
    attr_accessor :region
    attr_accessor :aws_credentials

    def init_aws_credentials(credentials)
      @aws_credentials = Aws::Credentials.new(
        credentials.fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']),
        credentials.fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY'])
      )
    end

    def s3
      @s3 ||= Aws::S3::Resource.new(
        credentials: aws_credentials,
        region: region
      )
    end

    def encrypt_args
      @kms_args || {}
    end

    def init_kms(opt)
      return nil unless opt

      kms = Aws::KMS::Client.new(
        region: @region,
        credentials: @aws_credentials
      )

      ciphertext = opt.fetch(:ciphertext)
      algorithm = opt.fetch(:algorithm, 'AES256')
      key = kms.decrypt(ciphertext_blob: Base64.decode64(ciphertext)).plaintext

      @kms_args = {
        sse_customer_algorithm: algorithm,
        sse_customer_key: key
      }
    end
  end

  # S3 File extractor
  # Used to extract files from Amazon S3
  #
  # @example Standard use
  #
  #  class MyJob < Remi::Job
  #    source :some_file do
  #      extractor Remi::Extractor::S3File.new(
  #        credentials: {
  #          aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #          aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #          region: 'us-west-2'
  #        },
  #        bucket: 'my-awesome-bucket',
  #        remote_path: 'some_file-',
  #        most_recent_only: true
  #      )
  #      parser Remi::Parser::CsvFile.new(
  #        csv_options: {
  #          headers: true,
  #          col_sep: '|'
  #        }
  #      )
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.some_file.df
  #  # =>#<Daru::DataFrame:70153153438500 @name = 4c59cfdd-7de7-4264-8666-83153f46a9e4 @size = 3>
  #  #                    id       name
  #  #          0          1     Albert
  #  #          1          2      Betsy
  #  #          2          3       Camu
  #
  # @example Using AWS KMS
  # To use AWS KMS, supply a :ciphertext and optional :algorithm (default is AES256).
  # The encrypted key stored in the ciphertext must be the same as that used when the file was written.
  #
  #  class MyJob < Remi::Job
  #    source :some_file do
  #      extractor Remi::Extractor::S3File.new(
  #        credentials: {
  #          aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #          aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #          region: 'us-west-2'
  #        },
  #        bucket: 'my-awesome-bucket',
  #        remote_path: 'some_file-',
  #        most_recent_only: true,
  #        kms_opt: {
  #          ciphertext: '<base64-encoded ciphertext>'
  #        }
  #      )
  #      parser Remi::Parser::CsvFile.new(
  #        csv_options: {
  #          headers: true,
  #          col_sep: '|'
  #        }
  #      )
  #    end
  #  end
  class Extractor::S3File < Extractor::FileSystem
    include Remi::DataSubject::S3File

    # @param bucket [String] Name of S3 bucket containing the files
    # @param kms_opt [Hash] Hash containing AWS KMS options
    # @param credentials [Hash] Hash containing AWS credentials (must contain :aws_access_key_id, :aws_secret_access_key, :region)
    def initialize(*args, **kargs, &block)
      super
      init_s3_file(*args, **kargs, &block)
    end

    # Called to extract files from the source filesystem.
    # @return [Array<String>] An array of paths to a local copy of the files extacted
    def extract
      entries.map do |entry|
        local_file = File.join(@local_path, entry.name)
        logger.info "Downloading #{entry.pathname} from S3 to #{local_file}"
        File.open(local_file, 'wb') { |file| entry.raw.get({ response_target: file }.merge(encrypt_args)) }
        local_file
      end
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries
      @all_entries ||= all_entries!
    end

    # @return [Array<Extractor::FileSystemEntry>] List of objects in the bucket/prefix
    def all_entries!
      # S3 does not track anything like a create time, so use last modified for both
      s3.bucket(@bucket_name).objects(prefix: @remote_path.to_s).map do |entry|
        Extractor::FileSystemEntry.new(
          pathname: entry.key,
          create_time: entry.last_modified,
          modified_time: entry.last_modified,
          raw: entry
        )
      end
    end

    private

    def init_s3_file(*args, credentials: {}, bucket:, kms_opt: nil, **kargs)
      @region = credentials.fetch(:region, 'us-west-2')
      init_aws_credentials(credentials)
      init_kms(kms_opt)

      @bucket_name = bucket
    end
  end



  # S3 File loader
  # Used to post files to Amazon S3
  #
  # @example Standard use
  #
  #  class MyJob < Remi::Job
  #    target :some_file do
  #      encoder Remi::Encoder::CsvFile.new
  #      loader Remi::Loader::S3File.new(
  #        credentials: {
  #          aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #          aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #          region: 'us-west-2'
  #        },
  #        bucket: 'itk-de-archive',
  #        remote_path: 'awesome.csv'
  #      )
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.some_file.df = Daru::DataFrame.new(
  #    {
  #      numbers: [1,2,3],
  #      words: ['one', 'two', 'three']
  #    }
  #  )
  #  job.some_file.load
  #
  # @example Using AWS KMS
  # To use AWS KMS, supply a :ciphertext and optional :algorithm (default is AES256).
  # The encrypted key stored in the ciphertext must be the same as that used for reading the file.
  #
  #  class MyJob < Remi::Job
  #    target :some_file do
  #      encoder Remi::Encoder::CsvFile.new
  #      loader Remi::Loader::S3File.new(
  #        credentials: {
  #          aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  #          aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
  #          region: 'us-west-2'
  #        },
  #        bucket: 'itk-de-archive',
  #        remote_path: 'awesome.csv',
  #        kms_opt: {
  #          ciphertext: '<base64-encoded ciphertext>'
  #        }
  #      )
  #    end
  #  end
  #
  # @example Generating a ciphertext
  # A ciphertext can be generated using the AWS SDK
  #
  #  require 'aws-sdk'
  #  require 'base64'
  #
  #  aws_credentials = Aws::Credentials.new(
  #    ENV['AWS_ACCESS_KEY_ID'],
  #    ENV['AWS_SECRET_ACCESS_KEY']
  #  )
  #
  #  kms = Aws::KMS::Client.new(
  #    region: 'us-west-2',
  #    credentials: aws_credentials
  #  )
  #
  #  # See AWS docs for creating keys: http://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html
  #  data_key = kms.generate_data_key(
  #    key_id: 'alias/alias-of-kms-key',
  #    key_spec: 'AES_256'
  #  )
  #
  #  ciphertext = Base64.strict_encode64(data_key.ciphertext_blob)
  #  #=> "AQIDAHjmmRVcBAdMHsA9VUoJKgbW8niK2qL1qPcQ2OWEUlh5XAFw0vfl+QIgawB8cbAZ2OqXAAAAfjB8BgkqhkiG9w0BBwagbzBtAgEAMGgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMIUIFFh++2w4d9al7AgEQgDvSRXQCOPLSMOjRS/lM5uxuyRV47qInlKKBIezIaYzXuFu1sRU+L46HqRyS0XqR4flFJ/fc8yEj3pU1UA=="
  class Loader::S3File < Loader
    include Remi::DataSubject::S3File

    # @param bucket [String] Name of S3 bucket containing the files
    # @param kms_opt [Hash] Hash containing AWS KMS options
    # @param credentials [Hash] Hash containing AWS credentials (must contain :aws_access_key_id, :aws_secret_access_key, :region)
    def initialize(*args, **kargs, &block)
      super
      init_s3_loader(*args, **kargs, &block)
    end

    attr_reader :remote_path

    # Copies data to S3
    # @param data [Object] The path to the file in the temporary work location
    # @return [true] On success
    def load(data)
      @logger.info "Writing file #{data} to #{@bucket_name} as #{@remote_path}"
      s3.bucket(@bucket_name).object(@remote_path).upload_file(data, encrypt_args)
      true
    end

    private

    def init_s3_loader(*args, credentials:{}, bucket:, remote_path:, kms_opt: nil, **kargs, &block)
      @region = credentials.fetch(:region, 'us-west-2')
      init_aws_credentials(credentials)
      init_kms(kms_opt)

      @bucket_name = bucket
      @remote_path = remote_path
    end
  end
end
