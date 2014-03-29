module Remi
  module Variables
    class DatasetVariableAccessor
      include Log

      def initialize(ds)
        @dataset = ds
      end

      def define(var_name,var_meta={})
        if @dataset.vars.has_key?(var_name)
          @dataset.vars.merge!(var_meta)
        else
        var_meta.merge!({:type => "string"}) unless var_meta.has_key?(:type)
          defaults = {:type => "string", :position => @dataset.vars.length + 1}
          @dataset.vars[var_name] = defaults.merge(var_meta)
          @dataset.row << nil
        end
        logger.debug "VARIABLE> #{var_name} >> #{@dataset.vars[var_name]}"
      end

      # presumably we would have a define, add, and remove metadata methods
      # with their own validations

    end

    def self.describe(*datasets,&b)
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
