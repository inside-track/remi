module Remi

  # Namespaces for specific sources/targets
  module DataSource; end
  module DataTarget; end

  class DataSubject
    def initialize(*args, fields: Remi::Fields.new, remi_df_type: :daru, logger: Remi::Settings.logger, **kargs, &block)
      @fields = fields
      @remi_df_type = remi_df_type
      @logger = logger
    end

    attr_accessor :fields

    def field_symbolizer
      Remi::FieldSymbolizers[:standard]
    end

    def df
      @dataframe ||= Remi::DataFrame.create(@remi_df_type, [], order: @fields.keys)
    end

    def df=(new_dataframe)
      if new_dataframe.respond_to? :remi_df_type
        @dataframe = new_dataframe
      else
        @dataframe = Remi::DataFrame.create(@remi_df_type, new_dataframe)
      end
    end

    module DataSource

      # Public: Access the dataframe from a DataSource
      #
      # Returns a Remi::DataFrame
      def df
        @dataframe ||= to_dataframe
      end

      # Public: Memoized version of extract!
      def extract
        @extract ||= extract!
      end

      # Public: Called to extract data from the source.
      #
      # Returns data in a format that can be used to create a dataframe.
      def extract!
        raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
        @extract
      end

      # Public: Converts extracted data to a dataframe
      #
      # Returns a Remi::DataFrame
      def to_dataframe
        raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
      end
    end

    module DataTarget

      # Public: Loads data to the target.  This is automatically called
      # after all transforms have executed, but could also get called manually.
      # The actual load operation is only executed if hasn't already.
      #
      # Returns true if the load operation was successful.
      def load
        return true if @loaded || df.size == 0

        @loaded = load!
      end

      # Public: Performs the load operation, regardless of whether it has
      # already executed.
      #
      # Returns true if the load operation was successful
      def load!
        raise NoMethodError, "#{__method__} not defined for #{self.class.name}"

        false
      end
    end
  end
end
