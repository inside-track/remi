module Remi

  # Sftp File extractor
  # Used to extract files from an SFTP server
  #
  # @example
  #
  # class MyJob < Remi::Job
  #   source :some_file do
  #     extractor Remi::Extractor::SftpFile.new(
  #       credentials: {
  #         host: 'coolserver.com',
  #         username: 'myself',
  #         password: 'secret'
  #       },
  #       remote_path: '/',
  #       pattern: /^some_file_\d{14}\.csv/,
  #       most_recent_only: true
  #     )
  #
  #     parser Remi::Parser::CsvFile.new(
  #       csv_options: {
  #         headers: true,
  #         col_sep: ','
  #       }
  #     )
  #   end
  # end
  #
  # job = MyJob.new
  # job.some_file.df
  #  # =>#<Daru::DataFrame:70153153438500 @name = 4c59cfdd-7de7-4264-8666-83153f46a9e4 @size = 3>
  #  #                    id       name
  #  #          0          1     Albert
  #  #          1          2      Betsy
  #  #          2          3       Camu
  class Extractor::SftpFile < Extractor::FileSystem
    N_RETRY = 3

    # @param credentials [Hash] Options hash containing login credentials
    # @param credentials [String] :host SFTP host (e.g., coolserver.com)
    # @param credentials [String] :username SFTP username
    # @param credentials [String] :password SFTP password
    # @param credentials [String] :port SFTP port (default: 22)
    def initialize(*args, **kargs, &block)
      super
      init_sftp_extractor(*args, **kargs)
    end

    attr_reader :host
    attr_reader :username
    attr_reader :password
    attr_reader :port

    # Called to extract files from the source filesystem.
    # @return [Array<String>] An array of paths to a local copy of the files extacted
    def extract
      connection do |sftp|
        entries.map do |entry|
          local_file = File.join(@local_path, entry.name)
          logger.info "Downloading #{entry.name} to #{local_file}"
          retry_download { sftp.download!(File.join(@remote_path, entry.name), local_file) }
          local_file
        end
      end
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries
      @all_entries ||= all_entries!
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries!
      sftp_entries = connection { |sftp| sftp.dir.entries(@remote_path) }
      sftp_entries.map do |entry|
        # Early versions of the protocol don't support create time, fake it with modified time?
        FileSystemEntry.new(
          pathname: File.join(@remote_path, entry.name),
          create_time: entry.attributes.respond_to?(:createtime) ? entry.attributes.createtime : entry.attributes.mtime,
          modified_time: entry.attributes.mtime
        )
      end
    end


    private

    def init_sftp_extractor(*args, credentials:, **kargs)
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
          raise err unless itry < N_RETRY
          logger.error "Download failed with error: #{err.message}"
          logger.error "Retry attempt #{itry}/#{N_RETRY-1}"
          sleep(1)
        end
      end
    end
  end



  # SFTP file loader
  #
  # @example
  #  class MyJob < Remi::Job
  #    target :my_target do
  #      encoder Remi::Encoder::CsvFile.new(
  #        csv_options: { col_sep: '|' }
  #      )
  #      loader Remi::Loader::SftpFile.new(
  #        credentials: { },
  #        remote_path: 'some_test.csv'
  #      )
  #      loader Remi::Loader::SftpFile.new(
  #        credentials: { },
  #        remote_path: 'some_other_test.csv'
  #      )
  #    end
  #  end
  #
  #  my_df = Daru::DataFrame.new({ a: 1.upto(5).to_a, b: 6.upto(10) })
  #  job = MyJob.new
  #  job.my_target.df = my_df
  #  job.my_target.load
  class Loader::SftpFile < Loader

    # @param remote_path [String, Pathname] Full path to the file to be created on the target filesystem
    def initialize(*args, **kargs, &block)
      super
      init_sftp_loader(*args, **kargs, &block)
    end

    attr_reader :remote_path

    # Copies data to the SFTP Server
    # @param data [Object] The path to the file in the temporary work location
    # @return [true] On success
    def load(data)
      logger.info "Uploading #{data} to #{@credentials[:username]}@#{@credentials[:host]}: #{@remote_path}"
      connection do |sftp|
        retry_upload { sftp.upload! data, @remote_path }
      end

      true
    end


    private

    def init_sftp_loader(*args, credentials:, remote_path:, **kargs, &block)
      @credentials = credentials
      @remote_path = remote_path
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
          break
        rescue RuntimeError => err
          raise err unless itry < ntry
          logger.error "Upload failed with error: #{err.message}"
          logger.error "Retry attempt #{itry}/#{ntry-1}"
          sleep(1)
        end
      end
    end
  end
end
