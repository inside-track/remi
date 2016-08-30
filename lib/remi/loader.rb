module Remi
  # A loader is an object meant to load data into a some external system.
  # This is a parent class meant to be inherited by child classes that
  # define specific ways to load data.
  class Loader

    def initialize(*args, logger: Remi::Settings.logger, **kargs, &block)
      @logger = logger
    end

    attr_accessor :logger

    # Any child classes need to define a load method that loads data from
    # the given dataframe into the target system.
    # @param data [Remi::DataFrame] Data that has been encoded appropriately to be loaded into the target
    # @return [true] On success
    def load(data)
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end

  end
end
