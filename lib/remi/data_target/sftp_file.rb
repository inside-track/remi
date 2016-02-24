module Remi
  module DataTarget
    class SftpFile
      include DataTarget

      def initialize(credentials:, local_path:, remote_path: File.basename(local_path), logger: Remi::Settings.logger)
        @credentials = credentials
        @local_path = local_path
        @remote_path = remote_path
        @logger = logger
      end

      attr_reader :local_path
      attr_reader :remote_path

      def load
        return true if @loaded

        connection do |sftp|
          retry_upload { sftp.upload! @local_path, @remote_path }
        end

        @loaded = true
      end



      private

      def connection(&block)
        result = nil
        Net::SFTP.start(@credentials[:host], @credentials[:username], password: @credentials[:password], port: @credentials[:port] || '22') do |sftp|
          result = yield sftp
        end
        result
      end

      def retry_upload(ntry=2, &block)
        1.upto(ntry).each do |itry|
          begin
            block.call
          rescue RuntimeError => err
            raise err unless itry < ntry
            @logger.error "Upload failed with error: #{err.message}"
            @logger.error "Retry attempt #{itry}/#{ntry-1}"
            sleep(1)
          end
        end
      end


    end
  end
end
