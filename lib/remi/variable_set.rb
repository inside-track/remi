module Remi

  class VariableSet

    def initialize(vars = {}, &block)
      @vars = vars
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


    private


    # Private: Defines methods that are accessible only within a block that
    # is used to define a variable set.
    class VariableSetDelegator < SimpleDelegator

      # THIS SHOULD CONVERT PREVIOUSLY DEFINED VARIABLES INTO A HASH AND THEN CREATE
      # A NEW VARIABLE FROM THEM

      # Public: Creates new variable.
      #
      # key_val - A hash containing metadata that is merged into the
      # existing metadata.
      #
      # Returns nothing.
      def meta(key_val)
        self.to_hash.merge!(key_val)
      end

      # Public: Used to merge in all metadata from an existing variable.
      #
      # var - A variable object.
      #
      # Returns nothing.
      def like(var)
         self.to_hash.merge!(var.to_hash)
      end

      # Public: Alias for drop_meta! form within a modify! block.
      #
      # drop_list - A comma delimited list of keys to be excluded from the variable.
      #
      # Examples
      #   myvar.modify!
      #     drop_meta :some_meta
      #   end
      #
      # Returns nothing.
      def drop_meta(*drop_list)
        self.drop_meta!(*drop_list)
      end

      # Public: Alias for keep_meta! form within a modify! block.
      #
      # keep_list - A comma delimited list of keys to be retained in the variable.
      #
      # Examples
      #   myvar.modify!
      #     keep_meta :some_meta, :some_other_meta
      #   end
      #
      # Returns nothing.
      def keep_meta(*keep_list)
        self.keep_meta!(*keep_list)
      end


  end
end
