module Remi
  module Variables
    class Variable
      attr_reader :position, :mandatory_metadata

      def initialize(metadata,position)
        @mandatory_metadata = [:type]
        @default_metadata = { :type => "string" }
        @metadata = @default_metadata.merge(metadata)
        @position = position
      end

      def method_missing(method_name,*args,&block)
        @metadata.send(method_name,*args,&block)
      end

      def to_hash
        { :position => @position, :metadata => @metadata }
      end

      def to_s
        to_hash.to_s
      end
    end


    class DatasetVariableAccessor
      include Log

      def initialize(ds)
        @dataset = ds
      end


      def create(var_name,var_meta={})
        if @dataset.vars.has_key?(var_name)
          @dataset.vars[var_name] = Variable.new(var_meta,@dataset.vars[var_name].position)
        else
          @dataset.vars[var_name] = Variable.new(var_meta,@dataset.vars.length)
          @dataset.row << nil
          @dataset.prev_row << nil
          @dataset.next_row << nil
        end
        logger.debug "VARIABLE> #{var_name} >> #{@dataset.vars[var_name]}"
      end

      # I also need some maniditory metadata that doesn't get keeped/dropped
      
      def modify_meta(var_name,var_meta = {})
        raise "Unknown variable <#{var_name}>" unless @dataset.vars.has_key?(var_name)
        @dataset.vars[var_name].merge!(var_meta)
      end

      
      def drop_meta(var_name,*drop)
        @dataset.vars[var_name].each do |key,value|
          next if @dataset.vars[var_name].mandatory_metadata.include? key
          @dataset.vars[var_name].delete(key) if drop.include? key
        end
      end

      
      def keep_meta(var_name,*keep)
        @dataset.vars[var_name].each do |key,value|
          next if @dataset.vars[var_name].mandatory_metadata.include? key
          @dataset.vars[var_name].delete(key) unless keep.include? key
        end
      end


      def import(source, options={})
        if source.is_a?(Dataset)
          import_from_dataset(source, options)
        else
          raise "Unknown source <#{source.class.name}> for variable import"
        end
      end

      def import_from_dataset(ds, keep: [], drop: [])
        ds_already_open = ds.is_open?

        ds.open_for_read unless ds_already_open
        logger.info "IMPORTING> **#{ds.name}**"

        ds.vars.each do |var_name,var_meta|
          if (keep.empty? or keep.include? var_name) and not drop.include? var_name
            create var_name, var_meta
          end
        end
        ds.close unless ds_already_open
      end

    end

    def self.define(*datasets,&b)
      datasets.each do |ds|
        yield DatasetVariableAccessor.new(ds)
      end
    end

  end
end
