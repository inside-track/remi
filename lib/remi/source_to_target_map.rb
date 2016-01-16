module Remi
  class SourceToTargetMap
    def initialize(source_df, target_df=nil)
      @source_df = source_df
      @target_df = target_df || @source_df

      reset_map
    end

    def self.apply(source_df, target_df=nil, &block)
      target_df ||= source_df
      Docile.dsl_eval(SourceToTargetMap.new(source_df, target_df), &block)
    end

    def source(*source_fields)
      @source_fields = Array(source_fields)
      self
    end

    def transform(*transforms)
      @transforms += Array(transforms)
      self
    end

    def target(*target_fields)
      @target_fields = Array(target_fields)
      self
    end

    def reset_map
      @source_fields = []
      @target_fields = []
      @transforms = []
    end

    def map(*args)
      case
      when @source_fields.include?(nil)
        do_map_generic
      when @source_fields.size == 1 && @transforms.size == 0
        do_map_direct_copy
      when @source_fields.size == 1 && @target_fields.size == 1
        do_map_single_source_and_target_field
      else
        do_map_generic
      end

      reset_map
    end



    private

    def do_map_direct_copy
      @target_fields.each do |target_field|
        @target_df[target_field] = @source_df[@source_fields.first].dup
      end
    end

    def do_map_single_source_and_target_field
      @target_df[@target_fields.first] = @source_df[@source_fields.first].recode do |field_value|
        @transforms.reduce(field_value) { |value, tform| tform.call(*value) }
      end
    end

    def do_map_generic
      work_vector = if @source_fields.size == 1 && @source_fields.first != nil
        @source_df[@source_fields.first].dup
      elsif @source_fields.size > 1
        # It's faster to zip together several vectors and recode those than it is to
        # recode a dataframe row by row!
        Daru::Vector.new(@source_df[@source_fields.first].zip(*@source_fields[1..-1].map { |name| @source_df[name] }), index: @source_df.index)
      else
        Daru::Vector.new([], index: @source_df.index)
      end

      work_vector.recode! do |field_value|
        @transforms.reduce(field_value) { |value, tform| tform.call(*(value || [nil])) }
      end

      @target_fields.each_with_index do |target_field, field_idx|
        @target_df[target_field] = work_vector.recode do |field_value|
          if field_value.is_a?(Array) then
            field_value[field_idx]
          else
            field_value
          end
        end
      end
    end
  end
end
