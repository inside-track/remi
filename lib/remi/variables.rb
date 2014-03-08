module Remi
  class Variables
    include Enumerable
    include Log

    attr_accessor :values

    def initialize
      @variables = {}
      @values = []
      @position = -1
    end


    def evaluate_block_vars(&b)
      self.instance_eval(&b)
    end

    def [](varname)
      @values[@variables[varname].position]
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

      ds.vars.each do |var_name,var_obj|
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
end
