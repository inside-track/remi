module Remi

  # S3 File extractor
  # Used to extract files from Amazon S3
  #
  # @example
  #
  #  class MyJob < Remi::Job
  #    source :some_file do
  #      extractor Remi::Extractor::S3File.new(
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
  class Extractor::S3File < Extractor::FileSystem

    # @param bucket_name [String] S3 bucket containing the files
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
        File.open(local_file, 'wb') { |file| entry.raw.get(response_target: file) }
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
      bucket.objects(prefix: @remote_path.to_s).map do |entry|
        Extractor::FileSystemEntry.new(
          pathname: entry.key,
          create_time: entry.last_modified,
          modified_time: entry.last_modified,
          raw: entry
        )
      end
    end

    # @return [Aws::S3::Client] The S3 client used
    def s3_client
      @s3_client ||= Aws::S3::Client.new
    end

    private

    def init_s3_file(*args, bucket:, **kargs)
      @bucket_name = bucket
    end

    def bucket
      @bucket ||= Aws::S3::Bucket.new(@bucket_name, client: s3_client)
    end

  end
end
