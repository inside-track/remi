module Remi
  # An encoder is an object tha converts a dataframe into a form that can
  # be used by a Remi::Loader.  This is a parent class meant to be
  # inherited by child classes that define specific ways to parse
  # data.
  class Encoder

    # @param context [Object] The context (e.g., DataTarget) for the encoder (default: `nil`)
    # @param field_symbolizer [Proc] The field symbolizer to use for this encoder
    # @param fields [Remi::Fields] A hash of field metadata to be used by the encoder
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

    # Any child classes need to define an encode method that converts the
    # data subject's dataframe into a structure that can be loaded into the
    # target system.
    # @param dataframe [Remi::DataFrame] The dataframe to be encoded
    # @return [Object] The encoded data to be loaded into the target
    def encode(dataframe)
      raise NoMethodError, "#{__method__} not defined for #{self.class.name}"
    end

    # @return [Proc] The field symbolizer (uses the context field symbolizer if defined)
    def field_symbolizer
      return context.field_symbolizer if context if context.respond_to? :field_symbolizer
      @field_symbolizer
    end

    # @return [Remi::Fields] The fields (uses the context fields if defined)
    def fields
      return context.fields if context && context.respond_to?(:fields)
      @fields
    end
  end
end
