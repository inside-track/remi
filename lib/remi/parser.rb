module Remi
  # A parser is an object that converts data returned from an
  # Remi::Extractor into a dataframe.  This is a parent class meant to be
  # inherited by child classes that define specific ways to parse
  # data.
  class Parser

    # @param context [Object] The context (e.g., DataSource) for the parser (default: `nil`)
    # @param field_symbolizer [Proc] The field symbolizer to use for this parser
    # @param fields [Remi::Fields] A hash of field metadata to be used by the parser
    def initialize(*args, context: nil, field_symbolizer: Remi::FieldSymbolizers[:standard], fields: Remi::Fields.new({}), logger: Remi::Settings.logger, **kargs, &block)
      @context = context
      @field_symbolizer = field_symbolizer

      @fields = fields
      @logger = logger
    end

    attr_accessor :context
    attr_accessor :logger
    attr_writer :field_symbolizer
    attr_writer :fields

    # Any child classes need to define a parse method that converts extracted data
    # into a dataframe.
    # @param data [Object] Extracted data that needs to be parsed
    # @return [Remi::DataFrame] The data converted into a dataframe
    def parse(data)
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end

    # @return [Proc] The field symbolizer (uses the context field symbolizer if defined)
    def field_symbolizer
      return context.field_symbolizer if context.respond_to? :field_symbolizer
      @field_symbolizer
    end

    # @return [Remi::Fields] The fields (uses the context fields if defined)
    def fields
      return context.fields if context if context.respond_to? :fields
      @fields
    end
  end
end
