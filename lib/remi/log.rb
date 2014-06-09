module Remi

  # Public: RemiLog is a module that provides a singleton object to perform
  # logging activity across all classes and objects.  By default, Remi sets
  # up two loggers - a system logger (RemiLog.sys) and a row-level logger (RemiLog.sys)
  # but more loggers can be defined if needed.  The purpose of having multiple
  # loggers is to allow for setting each logger at different logging levels.  So, for
  # example, the system logger could be set to Debug while the the row-level logger
  # is set to Error.
  #
  # Examples
  #
  #   # Create a new logger named 'user' and set it's repoting level to INFO
  #   RemiLog.user.level = Logger::INFO
  #
  #   # Write a message to the logger
  #   RemiLog.user.info "Doing something really cool here!"
  module RemiLog

    # Single instance hash that holds all loggers defined
    @loggers = {}

    class << self

      # Public: Used to access or create logger instances.
      #
      # m - Name of the logger.
      # *args - args[0] is used to define the logger output method when initially configured.
      #
      # Examples
      #
      # RemiLog.user # Creates a new logger
      # string = StringIO.new
      # RemiLog.usertest string # Creates a new logger that outputs to a StringIO object
      #
      # Returns a Logger instance
      def method_missing(m,*args)
        @loggers[m] ||= configure_logger_for(m,*args)
      end

      # Public: Delete a logger.  Once initialized, the logger output method cannot
      # be changed.  However, the logger can be deleted and restarted to accomplish
      # the same effect.
      #
      # m - Name of the logger.
      #
      # Examples
      #
      # Remilog.delete :user
      #
      # Returns the logger object, but deletes it from the hash of loggers.
      def delete(m)
        @loggers.delete(m)
      end


      private

      # Internal: Creates a new logger
      #
      # m - Name of the logger.
      # *args - Optional arguments.  args[0] will set the output method.
      #
      # Returns the logger.
      def configure_logger_for(m,*args)
        logger = Logger.new(args[0] || RemiConfig.log.output)
        logger.level = RemiConfig.log.level
        logger.progname = m.upcase

        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} %-12s%-6s: %s\n" % ["[#{progname}]",severity,msg]
        end
        
        logger
      end

    end
  end
end
