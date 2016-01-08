module Remi
  module DataSubject
    def field_symbolizer
      Remi::FieldSymbolizers[:standard]
    end

    def df
      @dataframe ||= Daru::DataFrame.new([])
    end

    def df=(new_dataframe)
      @dataframe = new_dataframe
    end

    # Fields is a hash where the keys are the data field names and the values
    # are a hash of metadata.  DataFrames do not currently support metadata,
    # so the metdata will be empty unless overridden by the specific target.
    def fields
      df.vectors.to_a.reduce({}) do |h, v|
        h[v] = {}
        h
      end
    end
  end
end
