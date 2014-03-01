module Remi

  require 'logger'

  module Log

    @level = Logger::ERROR

    def logger
      @logger ||= Log.logger_for(self.class.name)
    end

    # Accessor method to set the log level
    def self.level(level)
      @level = level
    end


    @loggers = {}

    class << self
      
      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)

        logger = Logger.new(STDOUT)
        logger.level = @level
        logger.progname = classname

        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} [#{progname}]%6s: %s\n" % [severity,msg]
        end

        logger

      end
    end

  end
  

  class Testlogger

    include Log

    def initialize

      logger.unknown "This is an unknown message"
      logger.fatal "This is an fatal message"
      logger.error "This is an error message"
      logger.warn "This is a warn message"
      logger.info "This is an info message"
      logger.debug "This is a debug message"
    end

  end


end
