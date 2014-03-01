module Remi

  class Variables
#    include Enumerable


    def initialize

      @variables = {}
      @values = []
      @position = -1

    end


    def evaluate_block_vars(&b)

      self.instance_eval(&b)

    end


    # Statements in the define_variables block have access to the following methods

    def var(var_name,var_meta)

      puts "I should be defining #{var_name}, #{var_meta}"
      puts "position = #{@position}"

      if @variables.has_key?(var_name)
        @variables[var_name].add_meta(var_meta)
      else
        @variables[var_name] = Variable.new @position+=1, var_meta
        @values << nil
      end

    end


    def each

      @variables.each do |var_name,var_obj|
        
        yield var_name, @values[var_obj.position]

      end

    end

    def each_with_meta

      @variables.each do |var_name,var_obj|
        
        yield var_name, @values[var_obj.position], var_obj.meta

      end

    end


  end


  class Variable

    def initialize(position,meta)
      @position = position
      @meta = meta
    end

    attr_accessor :position
    attr_accessor :meta


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
