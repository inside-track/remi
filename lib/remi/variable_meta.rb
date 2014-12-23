module Remi

  # Public: Defines variable objects that contain metadata about data
  # columns.  The variable object is mostly a hash, but includes some
  # some mandatory keys and custom methods.
  #
  # Examples
  #
  #   var_simple = VariableMeta.new :length => 18, :label => "SalesForce Id"
  #
  #   var_w_regex_validation = VariableMeta.define do |v|
  #     v.like var_simple
  #     v.meta :regex  => /[a-zA-Z0-9]{15,18}/
  #   end
  #
  #   var_simple_again = var_w_regex_validation.drop_meta :regex
  #   var_simple_again = var_w_regex_validation.keep_meta :length, :label
  class VariableMeta
    include Enumerable

    extend Forwardable
    def_delegators :@metadata, :keys, :each, :has_key?, :[], :[]=, :include?


    # Required metadata default values
    DEFAULT = { :type => "string" }

    # Required metadata keys only
    MANDATORY_KEYS = DEFAULT.keys

    # Public: Initialize a new variable.
    #
    # meta - A hash containing metadata to be included in the variable.
    def initialize(meta={}, &block)
      @metadata = DEFAULT.merge(meta)

      modify(&block) if block_given?
    end

    attr_reader :metadata


    # Public: Used to modify variable metadata in a block.
    #
    # block - A block of commands used to manipulate variable metadata.
    #
    # Returns nothing.
    def modify(&block)
      Docile.dsl_eval(VariableMetaBlock.new(self), &block)
    end

    # Public: Converts a variable object into a hash.
    #
    # Returns a hash of the variable metadata.
    def to_hash
      @metadata.dup
    end

    # Public: Variable equality test.
    #
    # another_variable - Another variable object.
    #
    # Returns a boolean indicating whether two variables have the same metadata.
    def ==(another_variable)
      @metadata == another_variable.metadata
    end




    # Public: Creates a copy of a variable including all metadata keys
    # except those specified in the drop list (and except any mandatory keys).
    #
    # drop_list - A comma delimited list of keys to be excluded from the variable.
    #
    # Examples
    #   var_new = var_orig.drop_meta :some_metadata, :other
    #
    # Returns a new Variable object.
    def drop_meta(*drop_list)
      self.class.new(modify_collection(:reject, :-, *drop_list))
    end

    # Public: Removes all metadata keys from an existing variable
    # except those specified in the drop list (and except any mandatory keys).
    #
    # drop_list - A comma delimited list of keys to be excluded from the variable.
    #
    # Examples
    #   var_orig.drop_meta! :some_metadata, :other
    #
    # Returns the variable object.
    def drop_meta!(*drop_list)
      modify_collection(:delete_if, :-, *drop_list)
      self
    end

    # Public: Creates a copy of a variable including only those metadata keys
    # specified in the keep list (and any mandatory keys).
    #
    # keep_list - A comma delimited list of keys to be retained in the variable.
    #
    # Examples
    #   var_new = var_orig.keep_meta :length
    #
    # Returns a new Variable object.
    def keep_meta(*keep_list)
      self.class.new(modify_collection(:select, :+, *keep_list))
    end

    # Public: Removes from a variable all metadata keys except those
    # specified in the keep list (and any mandatory keys).
    #
    # keep_list - A comma delimited list of keys to be retained in the variable.
    #
    # Examples
    #   var_orig.keep_meta! :length
    #
    # Returns the variable object.
    def keep_meta!(*keep_list)
      modify_collection(:keep_if, :+, *keep_list)
      self
    end

    class VariableMetaBlock < SimpleDelegator

      # Public: Creates new metadata from a hash.
      #
      # key_val - A hash containing metadata that is merged into the
      # existing metadata.
      #
      # Returns nothing.
      def meta(key, value)
        self[key] = value
      end

      # Public: Used to merge in all metadata from an existing variable.
      #
      # var - A variable object.
      #
      # Returns nothing.
      def like(var)
        raise 'Expecting a VariableMeta' unless var.is_a? VariableMeta
        var.each do |key, meta|
          self[key] = meta
        end
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

    private

      # Private: Generic method used to add or remove metadata from a variable object.
      #
      # selector            - Hash method used to select the metadata
      #                       keys.  If a destructive method is used
      #                       like :delete_if or :keep_if, then the
      #                       metadata of self object is modified.  If a
      #                       non-destructive method like :reject or
      #                       :select is used, then a new metadata hash
      #                       is returned.
      # mandatory_join_sign - Symbol used to indicate whether the
      #                       mandatory keys should be included (:+) or
      #                       excluded (:-) from the supplied list of
      #                       keys in meta_list.
      # meta_list           - A list of metadata keys to add or remove.
      #
      # Returns a hash, which is either the object's metadata hash or a new metadata
      # hash that can be used to create a new variable object.
      def modify_collection(selector, mandatory_join_sign, *meta_list)
        trimmed_meta_list = meta_list.flatten.send(mandatory_join_sign, MANDATORY_KEYS).uniq
        @metadata.send(selector) { |key| trimmed_meta_list.include? key }
      end

  end
end
