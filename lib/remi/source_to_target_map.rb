module Remi

  # Public: Class used to define a DSL for source to target maps.
  #
  # Examples
  #
  #   SourceToTargetMap.apply(df) do
  #     map source(:a) .target(:aprime)
  #       .transform(->(v) { "#{v}prime" })
  #     map source(:a) .target(:aup)
  #       .transform(->(v) { "#{v.upcase}" })
  #   end
  #   #=> <Daru::DataFrame:70291322684920 @name = 8c546a52-c1a7-495a-996a-7f352b0087b7 @size = 3>
  #                         a     aprime       aup
  #              0         a1    a1prime        A1
  #              1         a2    a2prime        A2
  #              2         a3    a3prime        A3
  class SourceToTargetMap

    # Public: Initializes the SourceToTargetMap DSL
    #
    # source_df       - The source dataframe.
    # target_df       - The target dataframe (default: source_df).
    # source_metadata - Metadata (Remi::Fields) for the source fields.
    # target_metadata - Metadata (Remi::Fields) for the target fields.
    def initialize(source_df, target_df=nil, source_metadata: Remi::Fields.new, target_metadata: Remi::Fields.new)
      @source_df = source_df
      @source_metadata = source_metadata

      @target_df = target_df || source_df
      @target_metadata = target_metadata || source_metadata
    end

    attr_reader :source_df, :target_df

    # Public: Expects a block in which the DSL will be applied.
    #
    # Same arguments as the constructor.
    #
    # Returns the target dataframe.
    def self.apply(source_df, target_df=nil, source_metadata: Remi::Fields.new, target_metadata: Remi::Fields.new, &block)
      sttm = SourceToTargetMap.new(source_df, target_df, source_metadata: source_metadata, target_metadata: target_metadata)
      Docile.dsl_eval(sttm, &block)
      target_df || source_df
    end

    # Public: Adds a list of source vectors to a new mapping.
    #
    # source_vectors - A list of vector names.
    #
    # Returns a SourceToTargetMap::Map with the defined source vectors.
    def source(*source_vectors)
      new_map.source(*source_vectors)
    end

    # Public: Adds a list of targets vectors to a new mapping.
    #
    # target_vectors - A list of target names.
    #
    # Returns a SourceToTargetMap::Map with the defined target vectors.
    def target(*target_vectors)
      new_map.target(*target_vectors)
    end

    # Public: Executes a mapping.
    #
    # defined_map - The SourceToTargetMap::Map object to execute
    #
    # Returns the target dataframe.
    def map(defined_map)
      defined_map.execute
    end


    private

    # Public: Returns a new SourceToTargetMap::Map
    def new_map
      Map.new(@source_df, @target_df, source_metadata: @source_metadata, target_metadata: @target_metadata)
    end
  end
end
