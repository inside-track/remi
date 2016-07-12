module Remi
  class DataSubject
    def initialize(*args, fields: Remi::Fields.new, remi_df_type: :daru, logger: Remi::Settings.logger, **kargs, &block)
      @fields = fields
      @remi_df_type = remi_df_type
      @logger = logger
    end

    # Public: Fields defined for this data subject
    attr_accessor :fields

    # Public: The default method for symbolizing field names
    def field_symbolizer
      Remi::FieldSymbolizers[:standard]
    end

    # Public: Access the dataframe from a DataSource
    #
    # Returns a Remi::DataFrame
    def df
      @dataframe ||= Remi::DataFrame.create(@remi_df_type, [], order: @fields.keys)
    end

    # Public: Reassigns the dataframe associated with this subject
    #
    # Returns the assigned dataframe
    def df=(new_dataframe)
      if new_dataframe.respond_to? :remi_df_type
        @dataframe = new_dataframe
      else
        @dataframe = Remi::DataFrame.create(@remi_df_type, new_dataframe)
      end
    end

    # Public: Enforces types defined in the field metadata.
    # For example, if a field has metadata with type: :date, then the
    # type enforcer will convert data in that field into a date, and will
    # throw an error if it is unable to parse any of the values.
    #
    # types - If set, restricts the data types that are enforced to just those listed.
    #
    # Returns nothing.
    def enforce_types(*types)
      sttm = SourceToTargetMap.new(df, source_metadata: fields)
      fields.keys.each do |field|
        next unless (types.size == 0 || types.include?(fields[field][:type])) && df.vectors.include?(field)
        sttm.source(field).target(field).transform(Remi::Transform::EnforceType.new).execute
      end

      nil
    end
  end


  class DataSource < DataSubject

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


  class DataTarget < DataSubject

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
