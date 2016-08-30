module Remi
  # An extractor is an object meant to extract data from some external system.
  # This is a parent class meant to be inherited by child classes that
  # define specific ways to extract data.
  class Extractor

    def initialize(*args, logger: Remi::Settings.logger, **kargs, &block)
      @logger = logger
    end

    # @return [Object] The logger object used by the extractor
    attr_accessor :logger

    # Any child classes need to define an extract method that returns data
    # in a format that an appropriate parser can use to convert into a dataframe
    def extract
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end

  end
end
