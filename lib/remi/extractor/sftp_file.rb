module Remi
  module Extractor

    class SftpFile < FileSystem

      N_RETRY = 3

      def initialize(*args, **kargs)
        super
        init_sftp_file(*args, **kargs)
      end

      attr_reader :host
      attr_reader :username
      attr_reader :password
      attr_reader :port

      # Public: Called to extract files from the source filesystem.
      #
      # Returns an array with containing the paths to all files extracted.
      def extract
        connection do |sftp|
          entries.map do |entry|
            local_file = File.join(@local_path, entry.name)
            @logger.info "Downloading #{entry.name} to #{local_file}"
            retry_download { sftp.download!(File.join(@remote_path, entry.name), local_file) }
            local_file
          end
        end
      end

      # Public: Returns an array of all FileSystemEntry instances that are in the remote_path.
      def all_entries
        @all_entries ||= all_entries!
      end

      def all_entries!
        sftp_entries = connection { |sftp| sftp.dir.entries(@remote_path.dirname) }
        sftp_entries.map do |entry|
          # Early versions of the protocol don't support create time, fake it with modified time?
          FileSystemEntry.new(
            pathname: File.join(@remote_path.dirname, entry.name),
            create_time: entry.attributes.respond_to?(:createtime) ? entry.attributes.createtime : entry.attributes.mtime,
            modified_time: entry.attributes.mtime
          )
        end
      end


      private

      def init_sftp_file(*args, credentials:, **kargs)
        @host     = credentials.fetch(:host)
        @username = credentials.fetch(:username)
        @password = credentials.fetch(:password)
        @port     = credentials.fetch(:port, '22')
      end

      def connection(&block)
        result = nil
        Net::SFTP.start(@host, @username, password: @password, port: @port) do |sftp|
          result = yield sftp
        end
        result
      end

      def retry_download(&block)
        1.upto(N_RETRY).each do |itry|
          begin
            block.call
            break
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
