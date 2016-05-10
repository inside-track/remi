module Remi
  class SourceToTargetMap
    def initialize(source_df, target_df=nil, source_metadata: Remi::Fields.new, target_metadata: Remi::Fields.new)
      @source_df = source_df
      @source_metadata = source_metadata

      if target_df
        @target_df = target_df
        @target_metadata = target_metadata
      else
        @target_df = @source_df
        @target_metadata = @source_metadata
      end

      reset_map
    end

    def self.apply(source_df, target_df=nil, source_metadata: Remi::Fields.new, target_metadata: Remi::Fields.new, &block)
      sttm = SourceToTargetMap.new(source_df, target_df, source_metadata: source_metadata, target_metadata: target_metadata)
      Docile.dsl_eval(sttm, &block)
    end

    def source(*source_vectors)
      @source_vectors = Array(source_vectors)
      self
    end

    def transform(*transforms)
      @transforms += Array(transforms)
      @transform_procs += Array(transforms).map { |t| t.to_proc }
      self
    end

    def target(*target_vectors)
      @target_vectors = Array(target_vectors)
      self
    end

    def reset_map
      @source_vectors = []
      @target_vectors = []
      @transforms = []
      @transform_procs = []
    end

    def map(*args)
      inject_transform_with_metadata

      case
      when @source_vectors.include?(nil)
        do_map_generic
      when @source_vectors.size == 1 && @transforms.size == 0
        do_map_direct_copy
      when @source_vectors.size == 1 && @target_vectors.size == 1
        do_map_single_source_and_target_vector
      else
        do_map_generic
      end
      reset_map
    end



    private

    def inject_transform_with_metadata
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

    def do_map_direct_copy
      @target_vectors.each do |target_vector|
        @target_df[target_vector] = @source_df[@source_vectors.first].dup
      end
    end

    def do_map_single_source_and_target_vector
      @target_df[@target_vectors.first] = @source_df[@source_vectors.first].recode do |vector_value|
        @transform_procs.reduce(vector_value) { |value, tform| tform.call(*(value.nil? ? [nil] : value)) }
      end
    end

    def do_map_generic
      work_vector = if @source_vectors.size == 1 && @source_vectors.first != nil
        @source_df[@source_vectors.first].dup
      elsif @source_vectors.size > 1
        # It's faster to zip together several vectors and recode those than it is to
        # recode a dataframe row by row!
        Daru::Vector.new(@source_df[@source_vectors.first].zip(*@source_vectors[1..-1].map { |name| @source_df[name] }), index: @source_df.index)
      else
        Daru::Vector.new([], index: @source_df.index)
      end

      work_vector.recode! do |vector_value|
        @transform_procs.reduce(vector_value) { |value, tform| tform.call(*(value.nil? ? [nil] : value)) }
      end

      @target_vectors.each_with_index do |target_vector, vector_idx|
        @target_df[target_vector] = work_vector.recode do |vector_value|
          if vector_value.is_a?(Array) then
            vector_value[vector_idx]
          else
            vector_value
          end
        end
      end
    end
  end
end
