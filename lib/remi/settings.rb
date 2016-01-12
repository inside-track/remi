module Remi
  module Settings
    extend self

    def work_dir
      @work_dir ||= File.join(Dir.tmpdir, Dir::Tmpname.make_tmpname('',nil))
    end

    def work_dir=(arg)
      @work_dir = arg
    end

    def log_level
      @log_level ||= Logger::INFO
    end

    def log_level=(arg)
      @log_level = arg
    end

    def logger
      return @logger.call if @logger.respond_to? :call
      @logger ||= lambda do
        l = Logger.new(STDOUT)
        l.level = log_level
        l.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
        l
      end

      @logger.call
    end

    def logger=(arg)
      @logger = arg
    end
  end
end
