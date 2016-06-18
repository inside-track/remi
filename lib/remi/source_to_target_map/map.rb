module Remi
  class SourceToTargetMap

    # Public: Class used to perform source to target mappings.
    #
    # Examples
    #
    #   # One-to-one map
    #   map = Map.new(source_df, target_df)
    #   map.source(:a).target(:aprime)
    #     .transform(->(v) { "#{v}prime" })
    #   # see tests for more
    class Map

      # Public: Initializes a map
      #
      # source_df       - The source dataframe.
      # target_df       - The target dataframe (default: source_df).
      # source_metadata - Metadata (Remi::Fields) for the source fields.
      # target_metadata - Metadata (Remi::Fields) for the target fields.
      def initialize(source_df, target_df, source_metadata: Remi::Fields.new, target_metadata: Remi::Fields.new)
        @source_df = source_df
        @target_df = target_df

        @source_metadata = source_metadata
        @target_metadata = target_metadata

        @source_vectors  = []
        @target_vectors  = []
        @transforms      = []
        @transform_procs = []
      end

      # Public: Returns the map's source dataframe
      attr_reader :source_df

      # Public: Returns the map's target dataframe
      attr_reader :target_df

      # Public: Returns all of the map's source vectors
      attr_reader :source_vectors

      # Public: Returns all of the map's target vectors
      attr_reader :target_vectors

      # Public: Returns all of the map's defined transforms
      attr_reader :transforms


      # Public: Adds a list of source vectors to a map
      #
      # source_vectors - A list of source vectors.
      #
      # Returns self
      def source(*source_vectors)
        @source_vectors += Array(source_vectors)
        self
      end

      # Public: Adds a list of target vectors to a map
      #
      # target_vectors - A list of target vectors.
      #
      # Returns self
      def target(*target_vectors)
        @target_vectors += Array(target_vectors)
        self
      end

      # Public: Adds a transform to the map
      # A transform is an object that behaves like a proc and responds
      # to #call and #to_proc.  This method returns self, so transforms
      # may be chained.  They will be executed in the order that they are
      # applied to the map.
      #
      # tform - The transform to add
      #
      # Returns self
      def transform(tform)
        @transforms << tform
        @transform_procs << tform.to_proc
        self
      end

      # Public: Executes the map defined by the source vectors, target vectors, and transforms.
      #
      # Returns the target dataframe.
      def execute
        inject_transforms_with_metadata
        set_default_transform
        map_to_target_df
      end

      # Public: Returns the number of source vectors defined
      def source_cardinality
        @source_vectors.size
      end

      # Public: Returns the number of target vectors defined
      def target_cardinality
        @target_vectors.size
      end




      private

      def inject_transforms_with_metadata
        @transforms.each do |tform|
          if tform.respond_to? :source_metadata
            meta = @source_vectors.map { |v| @source_metadata[v] || {} }
            tform.source_metadata = meta.size > 1 ? meta : meta.first
          end
          if tform.respond_to? :target_metadata
            meta = @target_vectors.map { |v| @target_metadata[v] || {} }
            tform.target_metadata = meta.size > 1 ? meta : meta.first
          end
        end
      end

      # Private: If no transforms are defined, assume it's a simple copy
      def set_default_transform
        if @transforms.size == 0
          transform(->(v) { v })
        end
      end

      # Private: Converts the transformed data into vectors in the target dataframe.
      def map_to_target_df
        result_hash_of_arrays.each do |vector, values|
          @target_df[vector] = Daru::Vector.new(values, index: @source_df.index)
        end

        @target_df
      end

      # Private: Splits the transformed rows into separate arrays, indexed by vector name
      def result_hash_of_arrays
        result = @target_vectors.each_with_object({}) { |v,h| h[v] = [] }

        transformed_rows.each do |result_row|
          result.keys.each do |vector|
            result[vector] << result_row[vector]
          end
        end

        result
      end

      # Private: Applies all of the transforms to each row.
      def transformed_rows
        work_rows.map do |row|
          @transform_procs.each do |tform|
            result = call_transform(tform, row)
            row[*@target_vectors] = result if target_cardinality == 1
            row[*@source_vectors] = result if source_cardinality == 1 && target_cardinality == 1
          end

          row
        end
      end

      # Private: Applies the given transform to the given row.
      #
      # tform - The transform (proc).
      # row   - The row.
      #
      # Returns the return value of the transform.
      def call_transform(tform, row)
        if source_cardinality == 0 && target_cardinality == 1
          tform.call
        elsif source_cardinality == 1 && target_cardinality == 1
          tform.call(row[*@source_vectors])
        else
          tform.call(row)
        end
      end

      # Private: Returns a unique list of all vectors (source and target) invovled in the map.
      def all_vectors
        @all_vectors ||= (@source_vectors + @target_vectors).uniq
      end

      # Private: Returns a hash that maps vector names to an index
      # The index is the position of the vector value for a row in #work_rows
      def rows_index
        @rows_index ||= all_vectors.each_with_index.to_h
      end

      # Private: Converts all of vectors involved in the map into an array of row objects.
      def work_rows
        all_vectors.map do |vector|
          is_source_vector = @source_vectors.include? vector

          if is_source_vector && @source_df.vectors.include?(vector)
            @source_df[vector].to_a
          elsif is_source_vector && @target_df.vectors.include?(vector)
            @target_df[vector].to_a
          else
            Array.new(@source_df.size)
          end
        end.transpose.map do |row_as_array|
          Row.new(rows_index, row_as_array, source_keys: @source_vectors)
        end
      end
    end
  end
end
