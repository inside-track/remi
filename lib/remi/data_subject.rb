module Remi

  # The DataSubject is the parent class for DataSource and DataTarget.  It is not intended
  # to be used as a standalone class.
  #
  # A DataSubject is either a source or a target.  It is largely used to associate
  # a dataframe with a set of "fields" containing metadata describing how the vectors
  # of the dataframe are meant to be interpreted.  For example, one of the fields
  # might represent a date with MM-DD-YYYY format.
  #
  # DataSubjects can be defined either using the standard `DataSubject.new(<args>)`
  # convention, or through a DSL, which is convenient for data subjects defined
  # in as part of job class definition.
  class DataSubject

    # @param context [Object] the context in which the DSL is evaluated
    # @param name [Symbol,String] the name of the data subject
    # @param block [Proc] a block of code to be executed to define the data subject
    def initialize(context=nil, name: 'NOT DEFINED', **kargs, &block)
      @context = context
      @name = name
      @block = block
      @df_type = :daru
      @fields = Remi::Fields.new
      @field_symbolizer = Remi::FieldSymbolizers[:standard]
    end

    attr_accessor :context, :name


    # @param arg [Symbol] sets the type of dataframe to use for this subject
    # @return [Symbol] the type of dataframe (defaults to `:daru` if not explicitly set)
    def df_type(arg = nil)
      return get_df_type unless arg
      set_df_type arg
    end

    # @param arg [Hash, Remi::Fields] set the field metadata for this data subject
    # @return [Remi::Fields] the field metadata for this data subject
    def fields(arg = nil)
      return get_fields unless arg
      set_fields arg
    end

    # @param arg [Hash, Remi::Fields] set the field metadata for this data subject
    # @return [Remi::Fields] the field metadata for this data subject
    def fields=(arg)
      @fields = Remi::Fields.new(arg)
    end

    # Field symbolizer used to convert field names into symbols.  This method sets
    # the symbolizer for the data subject and also sets the symbolizers for
    # any associated parser and encoders.
    #
    # @return [Proc] the method for symbolizing field names
    def field_symbolizer(arg = nil)
      return @field_symbolizer unless arg
      @field_symbolizer = if arg.is_a? Symbol
                            Remi::FieldSymbolizers[arg]
                          else
                            arg
                          end
    end

    # @return [Remi::DataFrame] the dataframe associated with this DataSubject
    def df
      dsl_eval
      @dataframe ||= Remi::DataFrame.create(df_type, [], order: fields.keys)
    end

    # Reassigns the dataframe associated with this DataSubject.
    # @param new_dataframe [Object] The new dataframe object to be associated.
    # @return [Remi::DataFrame] the associated dataframe
    def df=(new_dataframe)
      dsl_eval
      if new_dataframe.respond_to? :df_type
        @dataframe = new_dataframe
      else
        @dataframe = Remi::DataFrame.create(df_type, new_dataframe)
      end
    end

    # Enforces the types defined in the field metadata.  Throws an
    # error if a data element does not conform to the type.  For
    # example, if a field has metadata with type: :date, then the type
    # enforcer will convert data in that field into a date, and will
    # throw an error if it is unable to parse any of the values.
    #
    # @param types [Array<Symbol>] a list of metadata types to use to enforce.  If none are given,
    #   all types are enforced.
    # @return [self]
    def enforce_types(*types)
      sttm = SourceToTargetMap.new(df, source_metadata: fields)
      fields.keys.each do |field|
        next unless (types.size == 0 || types.include?(fields[field][:type])) && df.vectors.include?(field)
        begin
          sttm.source(field).target(field).transform(Remi::Transform::EnforceType.new).execute
        rescue StandardError => err
          raise ArgumentError, "Field '#{field}': #{err.message}"
        end
      end

      self
    end

    # Defines the subject using the DSL in the block provided
    #
    # @return [self]
    def dsl_eval
      dsl_eval! unless @dsl_evaluated
      @dsl_evaluated = true
      self
    end

    def dsl_eval!
      return self unless @block
      Dsl.dsl_eval(self, @context, &@block)
    end

    private

    def set_fields(arg)
      self.fields = arg
    end

    def get_fields
      dsl_eval
      @fields
    end

    def set_df_type(arg)
      @df_type = arg
    end

    def get_df_type
      dsl_eval
      @df_type
    end
  end



  # The DataSource is a DataSubject meant to extract data from an external source
  # and convert (parse) it into a dataframe.
  #
  # @example
  #
  #   my_data_source = DataSource.new do
  #     extractor some_extractor
  #     parser some_parser
  #   end
  #
  #   my_data_source.df #=> Returns a dataframe that is created by extracting data
  #                     #   from some_extractor and parsing it using some_parser.
  class DataSource < DataSubject

    def initialize(*args, **kargs, &block)
      @parser = Parser::None.new
      @parser.context = self
      super
    end

    # @return [Array] the list of extractors that are defined for this data source
    def extractors
      @extractors ||= []
    end

    # @param obj [Object] adds an extractor object to the list of extractors
    # @return [Array] the full list of extractors
    def extractor(obj)
      extractors << obj unless extractors.include? obj
    end

    # @param obj [Object] sets the parser for this data source
    # @return [Object] the parser set for this data source
    def parser(obj = nil)
      return @parser unless obj
      obj.context = self

      @parser = obj
    end

    # Extracts data from all of the extractors.
    # @return [Array] the result of each extractor
    def extract!
      extractors.map { |e| e.extract }
    end

    # Converts all of the extracted data to a dataframe
    # @return [Remi::DataFrame]
    def parse
      parser.parse *extract
    end

    # The dataframe will only be extracted and parsed once, and only if it
    # has not already been set (e.g., using #df=).
    #
    # @return [Remi::DataFrame] the dataframe associated with this DataSubject
    def df
      @dataframe ||= parsed_as_dataframe
    end

    # This clears any previously extracted and parsed results.
    # A subsequent call to #df will redo the extract and parse.
    #
    # @return [Remi::DataFrame] the dataframe associated with this DataSubject
    def reset
      @block = nil
      @dataframe = nil
      @extract = nil
    end

    # @return [Array<Object>] all of the data extracted from the extractors (memoized).
    def extract
      @extract ||= extract!
    end


    private

    # Runs the DSL definitions and all extracts, parses, and enforced types
    # @return [Remi::DataFrame] the source extracted and parsed as a dataframe
    def parsed_as_dataframe
      dsl_eval if @block
      dataframe = parse
      dataframe
    end
  end


  # The DataTarget is a DataSubject meant to load data from an associated dataframe
  # into one or more target systems.
  #
  # @example
  #
  #   my_data_target = DataTarget.new do
  #     encoder some_encoder
  #     loader some_loader
  #   end
  #
  #   my_data_target.df = some_great_dataframe
  #   my_data_target.load #=> loads data from the dataframe into some target defined by some_loader
  class DataTarget < DataSubject

    def initialize(*args, **kargs, &block)
      @encoder = Encoder::None.new
      @encoder.context = self
      super
    end

    # @param obj [Object] sets the encoder for this data target
    # @return [Object] the encoder set for this data source
    def encoder(obj = nil)
      return @encoder unless obj
      obj.context = self

      @encoder = obj
    end

    # @return [Array] the list of loaders associated with the this data target
    def loaders
      @loaders ||= []
    end

    # @param obj [Object] adds a loader object to the list of loaders
    # @return [Array] the full list of loaders
    def loader(obj)
      obj.context = self
      loaders << obj unless loaders.include? obj
    end

    # Loads data to all targets.  This is automatically called
    # after all transforms have executed, but could also get called manually.
    # The actual load operation is only executed if hasn't already.
    #
    # @return [true] if successful
    def load
      return nil if @loaded || df.size == 0
      dsl_eval

      load!
      @loaded = true
    end

    # Performs the load operation, regardless of whether it has
    # already executed.
    #
    # @return [nil] nothing
    def load!
      loaders.each { |l| l.load encoded_dataframe }
      true
    end

    def df=(new_dataframe)
      super
      loaders.each { |l| l.load encoded_dataframe if l.autoload }
      df
    end

    private

    # @return [Object] the encoded data suitable for the loaders
    def encoded_dataframe
      @encoded_dataframe ||= encoder.encode df
    end

  end
end
