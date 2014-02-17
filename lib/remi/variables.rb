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
        tmp_vars = @vars.merge(var_name => var_meta)
      end

      unless tmp_vars[var_name].has_key?(:type)
        raise ":type not defined for variable #{var_name}"
      end

      @vars = tmp_vars

    end
    alias_method :var, :append_variables_hash

  end

end
