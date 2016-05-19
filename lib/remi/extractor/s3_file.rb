module Remi
  module Extractor

    class S3File < FileSystem

      def initialize(*args, **kargs, &block)
        super
        init_s3_file(*args, **kargs, &block)
      end

      # Public: Called to extract files from the source filesystem.
      #
      # Returns an array with containing the paths to all files extracted.
      def extract
        entries.map do |entry|
          local_file = File.join(@local_path, entry.name)
          @logger.info "Downloading #{entry.pathname} from S3 to #{local_file}"
          File.open(local_file, 'wb') { |file| entry.raw.get(response_target: file) }
          local_file
        end
      end

      # Public: Returns an array of all FileSystemEntry instances that are in the remote_path.
      def all_entries
        @all_entries ||= all_entries!
      end

      def all_entries!
        # S3 does not track anything like a create time, so use last modified for both
        bucket.objects(prefix: @remote_path.to_s).map do |entry|
          FileSystemEntry.new(
            pathname: entry.key,
            create_time: entry.last_modified,
            modified_time: entry.last_modified,
            raw: entry
          )
        end
      end

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
end
