module Remi
  module Variables
    class Variable
      attr_reader :position

      def initialize(metadata,position)
        @metadata = {:type => "string"}.merge(metadata)
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
          @dataset.vars[var_name] = Variable.new(var_meta,@dataset.vars.length + 1)
          @dataset.row << nil
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
          puts "drop = #{drop}"
          @dataset.vars[var_name].delete(key) if drop.include? key
        end
      end

      
      def keep_meta(var_name,*keep)
        @dataset.vars[var_name].each do |key,value|
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
        ds.open_for_read
        logger.info "IMPORTING> **#{ds.name}**"

        ds.vars.each do |var_name,var_meta|
          if (keep.empty? or keep.include? var_name) and not drop.include? var_name
            create var_name, var_meta
          end
        end
        ds.close
      end

    end

    def self.define(*datasets,&b)
      datasets.each do |ds|
        yield DatasetVariableAccessor.new(ds)
      end
    end

  end
=begin

  class _Variables
    include Enumerable
    include Log

    attr_accessor :values

    def initialize
      @variables = {} # Hash of variable objects
      @values = []
      @position = -1
    end


    def evaluate_block_vars(&b)
      self.instance_eval(&b)
    end

    def [](varname)
      @values[@variables[varname].position]
    end

    def meta(varname)
      @variables[varname].meta
    end

    def []= varname,value
      @values[@variables[varname].position] = value
    end

    # Statements in the define_variables block have access to the following methods


    def var(var_name,var_meta)
      logger.debug "VARAIBLE> #{var_name} at position #{@position+1} >> #{var_meta}"

      if @variables.has_key?(var_name)
        @variables[var_name].add_meta(var_meta)
      else
        @variables[var_name] = Variable.new @position+=1, var_meta
        @values << nil
      end
    end


    # Variables are imported in same order they were written, but not necessarily
    # from the same starting position
    def var_import(ds)
      ds.open_for_read
      logger.info "IMPORTING> **#{ds.name}**"

      ds.vars_each do |var_name,var_obj|
        var var_name, var_obj.meta
      end
      ds.close
    end


    def to_header
      h = {}
      @variables.each do |var_name,var_obj|
        h.merge!({ var_name => { 
            :position => var_obj.position, 
            :meta => var_obj.meta 
          } })
      end
      h
    end


    def to_msgpack
      to_header.to_msgpack
    end


    def has_key?(key)
      @variables.has_key?(key)
    end


    def each
      @variables.each do |var_name,var_obj|
        yield var_name, var_obj
      end
    end


    def each_with_values
      @variables.each do |var_name,var_obj|
        yield var_name, var_obj, @values[var_obj.position]
      end
    end
  end



  class Variable
    include Log

    attr_accessor :position
    attr_accessor :meta

    def initialize(position,meta)
      @position = position
      @meta = meta
    end


    # Might be garbage, but maybe I could use it for sorts?
    def swap_position(var)
      self.position,var.position = var.position,self.position
      nil
    end


    def add_meta(new_meta)
      @meta.merge!(new_meta)
    end

    def to_s
      "Variable: #{@position} - #{@meta}"
    end
  end
=end
end
