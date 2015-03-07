module Remi

  # Public: Defines variable set objects that collect variables and their
  # metadata.
  #
  # Examples
  #   account_vars = VariableSet.new account_id, name, address, premise_type, last_contact_date
  #
  #   account_vars = VariableSet.new do
  #     # Within a block, variable metdata can be defined at the same time
  #     var :account_id        => { :length => 18 } # set some metadata
  #     var :name              => {}                # use default metadata
  #     var :address           => address           # defined from an existing address variable
  #     var :premise_type      => { :valid_values => ['On-Premise', 'Off-Premise'] }
  #     var :last_contact_date => { :type => 'date' }
  #   end
  class VariableSet
    include Enumerable

    extend Forwardable
    def_delegators :@vars, :has_key?, :size, :include?

    # Public: Struct that associates an index with a VariableMeta instance.
    VariableWithIndex = Struct.new(:meta, :index) do
      # Public: Converting to hash removes any indexes.
      #
      # Returns a hash representing the Variable metadata.
      def to_hash
        self.meta.to_hash
      end
    end

    # Public: Initializes a new variable set.
    #
    # vars - A hash containing variables and metadata to be included in
    #        the variable set.
    def initialize(*args, &block)
      @vars = {}
      add_vars(*args)

      modify(&block) if block_given?
    end

    attr_reader :vars

    # Public: Used to define or modify variable sets in a block.
    #
    # block - A block of commands used to manipulate variable set.
    #
    # Returns nothing.
    def modify(&block)
      Docile.dsl_eval(VariableSetBlock.new(self), &block)
    end

    # Public: Array accessor reader method for variables.
    #
    # key - A variable key.
    #
    # Returns the variable object named key.
    def [](key)
      @vars[key]
    end

    # Public: Array accessor setter method for variables.
    #
    # key      - A variable key.
    # variable - Can be a hash representing variable metadata,
    #            a Variable object, or a VariableWithMetadata object.
    #
    # Returns nothing.
    def []=(key, variable)
      @vars[key] = case variable.class
                   when VariableWithIndex
                     variable
                   when VariableMeta
                     VariableWithIndex.new(variable, next_index(key))
                   else
                     VariableWithIndex.new(VariableMeta.new(variable), next_index(key))
                   end
    end

    # Public: Converts a VariableSet instance into a hash.
    #
    # Examples
    #   varset.to_hash.each { |k,v| puts k,v }
    #
    # Returns a hash of the variable set with variable names as keys
    # and variables as values.
    def to_hash
      @vars.dup
    end

    # Public: Creates a copy of a variable set including all variables
    # except those specified in the drop list.
    #
    # drop_list - A comma delimited list of keys to be excluded from the variable set.
    #
    # Examples
    #   varset_new = varset_orig.drop_vars :some_var, :other_var
    #
    # Returns a new VariableSet object.
    def drop_vars(*drop_list)
      self.class.new(modify_collection(:reject, *drop_list))
    end

    # Public: Removes all variable keys from an existing variable set
    # except those specified in the drop list.
    #
    # drop_list - A comma delimited list of keys to be excluded from the variable set.
    #
    # Examples
    #   varset_orig.drop_vars! :some_var, :other_var
    #
    # Returns self.
    def drop_vars!(*drop_list)
      modify_collection(:delete_if, *drop_list)
      reindex
      self
    end

    # Public: Creates a copy of a variable set including only those variables
    # specified in the keep list.
    #
    # keep_list - A comma delimited list of keys to be retained in the variable set.
    #
    # Examples
    #   varset_new = varset_orig.keep_vars :id
    #
    # Returns a new VariableSet object.
    def keep_vars(*keep_list)
      self.class.new(modify_collection(:select, *keep_list))
    end

    # Public: Removes from a variable set all variables except those
    # specified in the keep list.
    #
    # keep_list - A comma delimited list of keys to be retained in the variable set.
    #
    # Examples
    #   varset_orig.keep_vars! :id
    #
    # Returns self.
    def keep_vars!(*keep_list)
      modify_collection(:keep_if, *keep_list)
      reindex
      self
    end

    # Public: Adds variables to the variable set based on a list of arguments.  Each
    # element of the list can either be a symbol or a hash.  If a symbol is given,
    # then a variable is created with name of the symbol and using default variable
    # metadata.  If a hash is given, then a variable with the name of the hash
    # key is given and the hash value is used as metadata.  Multiple keys can
    # be provided in a single hash, and the value can either be another hash
    # represending variable metadata or a Variable object.
    #
    # args - Each element of the list is either a symbol or hash.
    #
    # Example:
    #   add_vars :myvar1, { :myvar2 => { :type => 'number' }, :myvar3 => Variable.new(:type => 'date') }, :myvar4
    #
    # Returns nothing.
    def add_vars(*args)
      args.each do |arg|
        if arg.is_a?(Symbol)
          self[arg] = {}
        else
          arg.each { |k,v| self[k] = v }
        end
      end
    end

    # Public: Loops over each variable in the variable set yielding the name
    # and VariableWithIndex.  Yielded variables are ordered by their index.
    #
    # Examples
    #   varset.each do |key, var|
    #     puts "#{key}: #{var.index}"
    #   end
    #
    # Yields a key/value pair.
    def each
      @vars.sort_by { |key, var| var.index }.each do |key, var|
        yield key, var
      end
    end

    # Public: Returns an array of the variable set keys (i.e., the variable names
    # composing the set).
    #
    # Returns an array.
    def keys
      self.collect { |key, var| key }
    end

    # Public: Reads through all of the variables in the VariableSet and assigns each
    # a new index.  Needed when variables are removed or inserted into the set.
    #
    # Returns nothing.
    def reindex
      new_index = 0.upto(self.size - 1).to_a

      self.each do |key, var|
        var.index = new_index.shift
      end

      nil
    end

    # Public: Orders variables according in the order of a supplied list of variables.
    #
    # order_ary - An array of variable names in the order that they should be stored.
    #             Any variables that are in the set but not listed as an argument
    #             will be moved after any listed variables.
    #
    # Examples
    #  varset.order(:name, :address, :account_id)
    #
    # Returns the VariableSet object.
    def reorder(*order_ary)
      ordered_keys = order_ary + (self.collect { |key, var| key} - order_ary)
      ordered_keys.each_with_index { |key, index| @vars[key].index = index }
      self
    end

    # Public: Variableset equality test.
    #
    # another_variableset - Another variableset object.
    #
    # Returns a boolean.
    def ==(another_variableset)
      @vars == another_variableset.vars
    end



    private

    # Private: Gets the next index for a new variable named var.  If
    # the variable already exists, it returns the index of that
    # variable.
    #
    # var - The name of the new variable.
    def next_index(var=nil)
      if @vars[var].nil? then
        @vars.size
      else
        @vars[var].index
      end
    end

    # Private: Generic method used to add or remove variables from a variable set.
    #
    # selector  - Hash method used to select the variable keys.  If a
    #             destructive method is used like :delete_if or
    #             :keep_if, then the variables of the self object is
    #             modified.  If a non-destructive method like :reject
    #             or :select is used, then a new variable hash is
    #             returned.
    # vars_list - A list of variable keys to add or remove.
    #
    # Returns a hash, which is either the object's variable hash or a new variable
    # hash that can be used to create a new variable set object.
    def modify_collection(selector, *vars_list)
      @vars.send(selector) { |key| vars_list.include? key }
    end

    class VariableSetBlock < SimpleDelegator

      # Public: Creates new variable.
      #
      # arg - A hash containing a key that is the variable name.
      #       The value of the hash is either another hash of variable metadata
      #       or a variable object.
      #
      # Returns nothing.
      def var(key, meta = {})
        self[key] = meta
      end

      # Public: Used to merge in all metadata from an existing variable.
      #
      # varset - A variable object.
      #
      # Returns nothing.
      def like(obj, keep: nil, drop: nil)
        raise 'Expecting a DataSet or VariableSet' unless [VariableSet, DataSet].include? obj.class
        variable_set = obj.is_a?(DataSet) ? obj.variable_set : obj

        variable_set.each do |key, variable|
          self[key] = variable unless (keep && !(Array(keep).include? key)) || (drop && (Array(drop).include? key))
        end
      end

      # Public: Alias for drop_vars! form within a modify block.
      #
      # drop_list - A comma delimited list of keys to be excluded from the variable set.
      #
      # Examples
      #   myvarset.modify
      #     drop_vars :some_var
      #   end
      #
      # Returns nothing.
      def drop_vars(*drop_list)
        self.drop_vars!(*drop_list)
      end

      # Public: Alias for keep_vars! form within a modify block.
      #
      # keep_list - A comma delimited list of keys to be retained in the variable set.
      #
      # Examples
      #   myvarset.modify
      #     keep_vars :some_var, :some_other_var
      #   end
      #
      # Returns nothing.
      def keep_vars(*keep_list)
        self.keep_vars!(*keep_list)
      end
    end
  end
end
