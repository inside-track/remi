require 'delegate'
module Remi

  class Variable

    # Required metadata keys and their default values
    MANDATORY_METADATA = { :type => "string" }

    def initialize(new_meta={})
      @metadata = MANDATORY_METADATA.merge(new_meta)
    end

    attr_accessor :metadata

    def has_key?(key)
      @metadata.has_key?(key)
    end

    def has_keys?(*keys)
      (keys - @metadata.keys).empty?
    end


    def self.define(&block)
      variable = new
      delegator = VariableDelegator.new(variable)
      delegator.instance_eval(&block)
      variable
    end



    def drop_meta(*drop_list)
      self.class.new(modify_collection(:reject, :-, *drop_list))
    end

    def drop_meta!(*drop_list)
      modify_collection(:delete_if, :-, *drop_list)
      self
    end

    def keep_meta(*keep_list)
      self.class.new(modify_collection(:select, :+, *keep_list))
    end

    def keep_meta!(*keep_list)
      modify_collection(:keep_if, :+, *keep_list)
      self
    end

    def modify_collection(selector, mandatory_join_sign, *meta_list)
      trimmed_meta_list = meta_list.flatten.send(mandatory_join_sign, MANDATORY_METADATA.keys).uniq
      @metadata.send(selector) { |key| trimmed_meta_list.include? key }
    end




    class VariableDelegator < SimpleDelegator
      def meta(key_val)
        self.metadata.merge!(key_val)
      end

      def like(var)
         self.metadata.merge!(var.metadata)
      end
    end





=begin OLD WORLD STUFF
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
        RemiLog.sys.debug "Creating variable #{var_name} >> #{@dataset.vars[var_name]}"
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
        RemiLog.sys.info "Importing variables from Dataset **#{ds.name}**"

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

=end
  end
end
