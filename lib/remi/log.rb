module Remi

  require 'logger'

  module Log

    def logger
      Log.logger
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)



    end

    # Accessor method to set the log level
    def self.level(level)
      logger.level = level
    end

  end
  

  class Testlogger

    include Log

    def initialize

      logger.progname = "MOFO"
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} [#{progname}]%6s: %s\n" % [severity,msg]
      end

      logger.unknown "This is an unknown message"
      logger.fatal "This is an fatal message"
      logger.error "This is an error message"
      logger.warn "This is a warn message"
      logger.info "This is an info message"
      logger.debug "This is a debug message"
    end

  end


end
