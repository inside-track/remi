module Remi
  # A loader is an object meant to load data into a some external system.
  # This is a parent class meant to be inherited by child classes that
  # define specific ways to load data.
  class Loader

    def initialize(*args, context: nil, logger: Remi::Settings.logger, **kargs, &block)
      @context = context
      @logger = logger
    end

    attr_accessor :logger, :context

    # Any child classes need to define a load method that loads data from
    # the given dataframe into the target system.
    # @param data [Remi::DataFrame] Data that has been encoded appropriately to be loaded into the target
    # @return [true] On success
    def load(data)
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end

    # If autoload is set to true, then any loaders are called at the moment
    # a dataframe is assigned to a target (e.g., `my_target.df = some_df` will
    # call `#load` on any loaders associated with `my_target`).
    def autoload
      false
    end

    # @return [Remi::Fields] The fields defined in the context
    def fields
      context && context.respond_to?(:fields) ? context.fields : Remi::Fields.new({})
    end
  end
end
