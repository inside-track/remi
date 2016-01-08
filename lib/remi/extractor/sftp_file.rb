module Remi
  module Extractor

    class LocalFile
      def initialize(path)
        @path = path
      end

      def extract
        @path
      end
    end

    class SftpFile

      class FileNotFoundError < StandardError; end

      def initialize(credentials:, remote_file:, remote_folder: '', local_folder: Settings.work_dir, port: '22', most_recent_only: false, logger: Remi::Settings.logger.new_logger)
        @credentials = credentials
        @remote_file = remote_file
        @remote_folder = remote_folder
        @local_folder = local_folder
        @port = port
        @most_recent_only = most_recent_only
        @logger = logger
      end

      attr_reader :logger

      def extract
        to_download = @most_recent_only ? Array(most_recent_entry(matching_entries)) : matching_entries
        raise FileNotFoundError, "File not found: #{@remote_file}" if to_download.size == 0
        download(to_download)
      end

      def all_entries(remote_folder = @remote_folder)
        @all_entries ||= connection { |sftp| sftp.dir.entries(File.join("/", remote_folder)) }
      end

      def matching_entries(match_name = @remote_file)
        all_entries.select { |e| match_name.match e.name }
      end

      def most_recent_entry(entries = matching_entries)
        entries.sort_by { |e| e.attributes.createtime }.reverse!.first
      end

      def download(to_download = matching_entries, local_folder: @local_folder, ntry: 3)
        connection do |sftp|
          to_download.map do |entry|
            local_file = File.join(local_folder, entry.name)
            @logger.info "Downloading #{entry.name} to #{local_file}"
            retry_download(ntry) { sftp.download!(entry.name, local_file) }
            local_file
          end
        end
      end


      private

      def connection(&block)
        result = nil
        Net::SFTP.start(@credentials[:host], @credentials[:username], password: @credentials[:password], port: @port) do |sftp|
          result = yield sftp
        end
        result
      end

      def retry_download(ntry=2, &block)
        1.upto(ntry).each do |itry|
          begin
            block.call
          rescue RuntimeError => err
            raise err unless itry < ntry
            @logger.error "Download failed with error: #{err.message}"
            @logger.error "Retry attempt #{itry}/#{ntry-1}"
            sleep(1)
          end
        end
      end
    end
  end
end
