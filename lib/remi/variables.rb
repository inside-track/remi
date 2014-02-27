module Remi

  module Variables

    extend self

    def evaluate_block_vars(vars,&b)
      @vars = vars
      self.instance_eval(&b)
      @vars
    end


    # Statements in the define_variables block have access to the following methods

    def append_variables_hash(var_name,var_meta)

      if @vars.has_key?(var_name)
        tmp_vars = @vars.merge(var_name => @vars[var_name].merge(var_meta))
      else
        @nvars += 1;
        tmp_vars = @vars.merge(var_name => var_meta)
      end

      unless tmp_vars[var_name].has_key?(:type)
        raise ":type not defined for variable #{var_name}"
      end

      @vars = tmp_vars

    end
    alias_method :var, :append_variables_hash

  end


  # A variable is an object that has a value and other metadata
  # variables in a dataset should be collected in an array and
  # have a position

  # NO!  The variable does not contain the value, it contains
  # a reference to position of the value in an array
  # I think this is more like a struct than a class kQ2MWuUKi6Qr
=begin
  class Variable

    def initialize(position)

      @value = nil
      @position = position
      @meta = {}
      
    end

    attr_accessor :value
    attr_accessor :meta

  end
=end  

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


=begin
  var1 = Variable.new(0,{:type => :string})
  var2 = Variable.new(1,{:type => :number})

  puts var1
  puts var2

  var1.swap_position(var2)

  
  puts var1
  puts var2

  var1.position = 3
  puts var1.position

  var1.meta[:myrule] = "Georgio"
  puts var1.meta
=end



end
