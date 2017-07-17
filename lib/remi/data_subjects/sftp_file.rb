module Remi
  module DataSubject::SftpFile

    attr_reader :sftp_session

    def sftp_retry(&block)
      tries ||= @retries

      block.call
    rescue StandardError => err
      if (tries -= 1) > 0
        logger.error "Error: #{err.message}"
        logger.error "Will retry #{tries} more times"
        sleep(@retry_interval)
        retry
      else
        raise err
      end
    end

    def begin_connection
      sftp_retry do
        Timeout.timeout(@timeout) do
          @ssh_session = Net::SSH.start(@host, @username, password: @password, port: @port, number_of_password_prompts: 0)
          @sftp_session = Net::SFTP::Session.new(@ssh_session)
          @sftp_session.connect!
        end
      end
    end

    def end_connection
      @sftp_session.close_channel unless @sftp_session.nil?
      @ssh_session.close unless @ssh_session.nil?

      Timeout.timeout(@timeout) do
        sleep 1 until (@sftp_session.nil? || @sftp_session.closed?) && (@ssh_session.nil? || @ssh_session.closed?)
      end
    end
  end



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
    include DataSubject::SftpFile

    # @param credentials [Hash] Options hash containing login credentials
    # @param credentials [String] :host SFTP host (e.g., coolserver.com)
    # @param credentials [String] :username SFTP username
    # @param credentials [String] :password SFTP password
    # @param credentials [String] :port SFTP port (default: 22)
    # @param retries [Integer] Number of times a connection or operation will be retried (default: 3)
    # @param timeout [Integer] Number of seconds to wait for establishing/closing a connection (default: 30)
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
      begin_connection

      entries.map do |entry|
        local_file = File.join(@local_path, entry.name)
        logger.info "Downloading #{entry.name} to #{local_file}"
        sftp_retry { sftp_session.download!(File.join(@remote_path, entry.name), local_file) }
        local_file
      end
    ensure
      end_connection
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries
      @all_entries ||= all_entries!
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries!
      sftp_session.dir.entries(@remote_path).map do |entry|
        # Early versions of the protocol don't support create time, fake it with modified time?
        FileSystemEntry.new(
          pathname: File.join(@remote_path, entry.name),
          create_time: entry.attributes.respond_to?(:createtime) ? entry.attributes.createtime : entry.attributes.mtime,
          modified_time: entry.attributes.mtime
        )
      end
    end


    private

    def init_sftp_extractor(*args, credentials:, retries: 3, retry_interval: 60, timeout: 30, **kargs)
      @host           = credentials.fetch(:host)
      @username       = credentials.fetch(:username)
      @password       = credentials.fetch(:password, nil)
      @port           = credentials.fetch(:port, '22')
      @retries        = retries
      @retry_interval = retry_interval
      @timeout        = timeout
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
    include DataSubject::SftpFile

    # @param credentials [Hash] Options hash containing login credentials
    # @param credentials [String] :host SFTP host (e.g., coolserver.com)
    # @param credentials [String] :username SFTP username
    # @param credentials [String] :password SFTP password
    # @param credentials [String] :port SFTP port (default: 22)
    # @param remote_path [String, Pathname] Full path to the file to be created on the target filesystem
    # @param retries [Integer] Number of times a connection or operation will be retried (default: 3)
    # @param timeout [Integer] Number of seconds to wait for establishing/closing a connection (default: 30)
    def initialize(*args, **kargs, &block)
      super
      init_sftp_loader(*args, **kargs, &block)
    end

    attr_reader :remote_path

    # Copies data to the SFTP Server
    # @param data [Object] The path to the file in the temporary work location
    # @return [true] On success
    def load(data)
      begin_connection

      logger.info "Uploading #{data} to #{@username}@#{@host}: #{@remote_path}"
      sftp_retry { sftp_session.upload! data, @remote_path }

      true
    ensure
      end_connection
    end


    private

    def init_sftp_loader(*args, credentials:, remote_path:, retries: 3, retry_interval: 60, timeout: 30, **kargs, &block)
      @host           = credentials.fetch(:host)
      @username       = credentials.fetch(:username)
      @password       = credentials.fetch(:password, nil)
      @port           = credentials.fetch(:port, '22')
      @remote_path    = remote_path
      @retries        = retries
      @retry_interval = retry_interval
      @timeout        = timeout
    end
  end
end
