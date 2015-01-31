module Remi

  # Public: The DataSetAccessor class simplifies accessing variables that are
  # common to multiple datasets.  A DataSetAccessor class is initialized in
  # one of two modes: intersect, or union.  In intersect mode, only those
  # variables that are common to all data sets involved can be accessed.
  # In union mode, all variables present in the data sets involved can be accessed.
  # When a variable is read that is present in more than one data set, only
  # the value for the last data set listed is retreived.
  #
  # Examples
  #
  #   ds = DataSetAccessor.union(ds1, ds2, ds3)
  #
  class DataSetAccessor

    class << self

      # Public: Creates a DataSetAccessor using the union method.
      def union(*args)
        new(:union, *args)
      end

      # Public: Creates a DataSetAccessor using the intersect method.
      def intersect(*args)
        new(:intersect, *args)
      end
    end

    class UnknownDataSetAccessorError < StandardError; end


    # Public: Initailizes a DataSetAccessor.
    #
    # method    - The method use to conjoin variable sets in each data set.
    #             Either :union or :intersect.
    # data_sets - A list of data sets to conjoin together to be accessed
    #             with the resultant DataSetAccessor
    def initialize(method, *data_sets)
      raise UnknownDataSetAccessorError, "Unknown method: #{method}" unless [:union, :intersect].include? method
      @data_sets = Array(data_sets)
      @merge_method = method
    end

    # Public: Passes arguments to the define_variables method of each data set
    # that is part of the DataSetAccessor.
    #
    # Returns nothing.
    def define_variables(*args, &block)
      @data_sets.each do |ds|
        ds.define_variables(*args, &block)
      end

      variable_set(:reload)
      conjoined_keys_by_data_set(:reload)
    end

    # Public: Returns the value of the variable named by the argument.  The value
    # returned is the value from the last data set listed when the DataSetAccessor
    # was defined.
    #
    # key - Variable name.
    #
    # Returns the value of the variable.
    def [](key)
      @data_sets.last[key]
    end

    # Public: Sets the value of the variable named by the argument for each
    # data set that is part of the DataSetAccessor.
    #
    # key   - Variable name.
    # value - Value to set.
    #
    # Returns nothing.
    def []=(key, value)
      @data_sets.each do |ds|
        ds[key] = value if conjoined_keys_by_data_set[ds][key]
      end
    end


    # Public: Returns a VariableSet containing all variables available through
    # the DataSetAccessor.
    #
    # operation - The VariableSet returned is memoized.  To recalculate
    #             it, set this to :reload.
    #
    # Returns a VariableSet.
    def variable_set(operation = false)
      @variable_set = nil if operation == :reload
      return @variable_set unless @variable_set.nil?

      conjoined_keys(:reload)
      @variable_set = VariableSet.new

      @data_sets.each do |ds|
        ds.variable_set.each do |key, var|
          @variable_set[key] = var if conjoined_keys.include? key
        end
      end

      @variable_set
    end

    # Public: Calls the write_row method for each data set in the DataSetAccessor.
    def write_row
      @data_sets.each do |ds|
        ds.write_row
      end
    end



    private


    # Private: Translates the conjoin method (:union, :intersect) into array operators.
    #
    # Returns a hash.
    def merge_operator
      @merge_operate ||= {
        :union => :+,
        :intersect => :&
      }
    end

    # Private: A memoized list of all VariableSet keys in the DataSetAccessor.
    #
    # Returns an array of variable keys.
    def conjoined_keys(operation = false)
      @conjoined_keys = nil if operation == :reload
      @conjoined_keys ||= @data_sets.collect { |ds| ds.variable_set.keys }.inject(merge_operator[@merge_method]).uniq
    end


    # Private: A memoized hash used to store whether a given data
    # set's variables are to be included in the DataSetAccessor.  The
    # keys of the returned hash are [:data_set][:variable_key] and the
    # value is true, indicating that the data set's keys are to be included.
    #
    # Returns a hash.
    def conjoined_keys_by_data_set(operation = false)
      @conjoined_keys_by_data_set = nil if operation == :reload
      return @conjoined_keys_by_data_set unless @conjoined_keys_by_data_set.nil?


      @conjoined_keys_by_data_set = {}
      conjoined_keys(:reload)

      @data_sets.each do |ds|
        @conjoined_keys_by_data_set[ds] = {}
        ds.variable_set.each do |key, var|
          @conjoined_keys_by_data_set[ds][key] = true if conjoined_keys.include? key
        end
      end

      @conjoined_keys_by_data_set
    end

  end
end
