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
  #     var :premise_type      => { :valid_values => ["On-Premise", "Off-Premise"] }
  #     var :last_contact_date => { :type => "date" }
  #   end
  class VariableSet

    # Public: Struct that associates an index with a Variable.
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
    def initialize(vars = {}, &block)
      @vars = {}
      @vars = vars_from_hash(vars)
      @index = []

      modify!(&block) if block_given?
    end


    # Public: Used to modify variable sets in a block.
    #
    # block - A block of commands used to manipulate variable set.
    #         The special set of methods available in this block can
    #         be found in the VariableSetDelegator class
    #
    # Returns nothing.
    def modify!(&block)
      delegator = VariableSetDelegator.new(self)
      delegator.instance_eval(&block)
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
    # variable - A variable object.
    #
    # Returns nothing.
    def []=(key, variable)
      @vars[key] = variable
    end

    # Public: Used to determine if a variable has been defined.
    #
    # key - A variable key.
    #
    # Returns true if the variable has been defined, false otherwise.
    def has_key?(key)
      @vars.has_key?(key)
    end

    # Public: Used to determine if each of a set of variables have been defined.
    #
    # keys - A comma delimited list of variable keys to check.
    #
    # Returns true if all of the variables have been defined, false otherwise.
    def has_keys?(*keys)
      (keys - @vars.keys).empty?
    end

    # Public: Converts a variable object into a hash.
    #
    # Examples
    #   varset.to_hash.each { |k,v| puts k,v }
    #
    # Returns a hash of the variable set with variable names as keys
    # and variables as values.
    def to_hash
      @vars
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
      self
    end

    # Public: Converts a hash that contains keys that are variable
    # names and values that are variable metadata (either Hash or
    # Variable object) into a hash that contains values that are
    # VariableWithIndex objects.
    #
    # var_hash - The hash containting variable name keys and variable metadata values.
    #
    # Returns a hash.
    def vars_from_hash(var_hash)
      result = {}
      var_hash.each do |name, var|
        result[name] = VariableWithIndex.new(Variable.new(var), next_index(name))
      end
      
      result
    end




    private

    # Private: Gets the next index for a new variable named var.  If
    # the variable already exists, it returns the index of that
    # variable.
    #
    # var - The name of the new variable.
    def next_index(var=nil)
      if @vars[var].nil? then
        @vars.length
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


    # Private: Defines methods that are accessible only within a block that
    # is used to define a variable set.
    class VariableSetDelegator < SimpleDelegator

      # Public: Creates new variable.
      #
      # key_val - A hash containing a key that is the variable name.
      #           The value of the hash is either another hash of variable metadata
      #           or a variable object.
      #
      # Returns nothing.
      def var(key_val)
        key_val.each do |key, val|
          variable = (val.is_a? Variable) ? val.dup : Variable.new(val)
          self.to_hash.merge!(vars_from_hash({ key => variable }))
        end
      end

      # Public: Used to merge in all metadata from an existing variable.
      #
      # var - A variable object.
      #
      # Returns nothing.
      def like(var)
        raise "Expecting a VariableSet" unless var.is_a? VariableSet
        self.to_hash.merge!(vars_from_hash(var.to_hash))
      end

      # Public: Alias for drop_vars! form within a modify! block.
      #
      # drop_list - A comma delimited list of keys to be excluded from the variable set.
      #
      # Examples
      #   myvarset.modify!
      #     drop_vars :some_var
      #   end
      #
      # Returns nothing.
      def drop_vars(*drop_list)
        self.drop_vars!(*drop_list)
      end

      # Public: Alias for keep_vars! form within a modify! block.
      #
      # keep_list - A comma delimited list of keys to be retained in the variable set.
      #
      # Examples
      #   myvarset.modify!
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
