# THIS IS WAY OVERKILL FOR REMI - I MOSTLY JUST NEED A LOG, NO ENV SETTINGS HERE
# SINCE THIS IS JUST A GEM.

module Remi
  module Settings
    extend self

    attr_accessor :config
    @config = Configatron::RootStore.new

    # Public: Redirects all methods to configuration parameter of the selected environment.
    def method_missing(name, val=nil)
      if name[-1] == '='
        @config[env][name.to_s.chomp('=').to_sym] = val
      else
        @config[env][name]
      end
    end

    # Public: Used to set the environment that should be used.
    #
    # val - One of: production, development, default
    #
    # Returns the name of the environment
    def set_env(val = (ENV['REMI_ENV'] || 'default').to_sym)
      @env = val
    end

    # Public: Returns the name of the currently selected environment.
    def env
      @env || set_env
    end

    # Private (intended): Method for creating a new logger.  This is needed as a separate
    # method because configatron.to_hash does not support Configatron::Dynamic.
    def new_logger
      Configatron::Dynamic.new do
        l = Logger.new(STDOUT)
        l.level = lambda { Settings.logger.level }.call
        l.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
        l
      end
    end


    @config.default do |c|
      c.logger do |l|
        l.new_logger = new_logger
        l.level = Logger::DEBUG
      end
      c.work_dir = '.'
    end

    # Might be cool to set these from a non-committed file that could
    # be unique to each developer.
    @config.development.configure_from_hash(@config.default.to_hash)
      c.logger.new_logger = new_logger
    @config.development do |c|
    end

    @config.test.configure_from_hash(@config.default.to_hash)
    @config.test do |c|
      c.logger.new_logger = new_logger
      c.work_dir = File.join(Dir.tmpdir, Dir::Tmpname.make_tmpname("TEST-",nil))
    end

    @config.production.configure_from_hash(@config.default.to_hash)
    @config.production do |c|
      c.logger.new_logger = new_logger
      c.work_dir = File.join(Dir.tmpdir, Dir::Tmpname.make_tmpname('',nil))
    end
  end
end
