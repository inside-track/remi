module Remi

  class DataTarget::SftpFile < DataTarget

    def initialize(*args, **kargs, &block)
      super
      init_sftp_file(*args, **kargs, &block)
    end

    attr_reader :local_path
    attr_reader :remote_path

    # Public: Performs the load operation, regardless of whether it has
    # already executed.
    #
    # Returns true if the load operation was successful
    def load!
      @logger.info "Uploading #{@local_path} to #{@credentials[:username]}@#{@credentials[:host]}: #{@remote_path}"
      connection do |sftp|
        retry_upload { sftp.upload! @local_path, @remote_path }
      end

      true
    end


    private

    def init_sftp_file(*args, credentials:, local_path:, remote_path: File.basename(local_path), **kargs, &block)
      @credentials = credentials
      @local_path = local_path
      @remote_path = remote_path
      init_df
    end

    def init_df
      parameter_df = Daru::DataFrame.new(
        local_path: Array(@local_path),
        remote_path: Array(@remote_path)
      )
      self.df = parameter_df
    end

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
