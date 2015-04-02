module Remi
  # Public: A row object is mostly just an array, with some additional
  # metadata to track the row number and whether the row is at the end
  # of the file (last_row).
  #
  # Examples
  #
  #   Row.new([1,2,3], last_row: true, row_number: 8)
  class Row
    extend Forwardable
    def_delegators :@row, :each

    # Public: Gets/sets the end of file flag.
    attr_accessor :last_row

    # Public: Gets/sets the row number.
    attr_accessor :row_number

    # Public: Gets the key_map in use.
    attr_reader :key_map

    class UnknownVariableKeyError < StandardError; end

    # Public: Initialize a new row.
    #
    # row        - An array of data representing the row.
    # last_row   - A flag indicating whether this is the last row in a data
    #              stream (default: false)
    # row_number - An integer indicating the row number of the data stream (default: nil).
    # key_map    - Provides a mapping between named keys and the index of the row array.
    #              Must return the index via key_map[:key].index (like a VariableWithIndex).
    def initialize(row = [], last_row: false, row_number: nil, key_map: nil)
      @last_row = last_row
      @row_number = row_number
      @key_map = key_map
      @row = row.empty? ? nilified_row : row.to_a

      initialize_accessor
    end


    # Public: Array accessor method to get a particular value from the row.
    #
    # key - A name or integer used to get the value of a particular element of the row.
    #       If a key_map is given, a name (symbol) is required.  Otherwise, the
    #       key must be an integer.
    #
    # Returns the value of the row element.
    def [](key)
      raise 'This method is intended to be defined as a singleton method'
    end

    # Public: Array accessor method to set a particular row element value.
    #
    # key   - A name or integer used to get the value of a particular element of the row.
    #         If a key_map is given, a name (symbol) is required.  Otherwise, the
    #         key must be an integer.
    # value - The value of the row element to be set.
    #
    # Returns the new value of the row element.
    def []=(key, value)
      raise 'This method is intended to be defined as a singleton method'
    end


    # Public: Copies the data and parameters of a row into this row object.
    # Paramters include last_row and row_number but NOT key_map.
    #
    # row - The row object to be copied
    #
    # Returns nothing.
    def copy(row)
      @row = row.to_a
      @last_row = row.last_row
      @row_number = row.row_number
    end

    # Public: Returns the array portion of the row.
    #
    # Returns an array.
    def to_a
      Array.new @row || nilified_row
    end

    # Public: Returns the size/length of the row.
    #
    # Returns an integer.
    def size
      @size ||= (@key_map || @row || []).size
    end
    alias length size

    # Public: Clears the row object by setting all elements to nil.
    #
    # Returns the row object.
    def clear
      @row = nilified_row
      self
    end


    # Public: Set the values of the row using an array.
    # Warning! No checks are performed to ensure that the size of the
    # given array conforms to the key_map.  If not correct, unexpected results
    # may arise.
    #
    # Returns the row array.
    def set_values(array)
      @row = array
    end

    # Public: Returns true if the row is empty (contains no values).
    #
    # Returns a boolean.
    def empty?
      @row.empty?
    end

    private

    # Private: Defines whether to use the index or keymap version of the
    # accessor methods.
    def initialize_accessor
      if @key_map
        self.define_singleton_method(:[], method(:get_row_by_map))
        self.define_singleton_method(:[]=, method(:set_row_by_map))
      else
        self.define_singleton_method(:[], method(:get_row_by_idx))
        self.define_singleton_method(:[]=, method(:set_row_by_idx))
      end
    end

    # Private: Returns a new empty array object that can be used to initialize
    # a row.
    def nilified_row
      (@nilified_row ||= Array.new(size)).dup
    end

    # Private: Uses the key map to get the value of a cell.
    def get_row_by_map(key)
      begin
        @row[@key_map[key].index]
      rescue => err
        raise UnknownVariableKeyError, "#{key} not defined" unless @key_map.has_key? key
        raise err
      end
    end

    # Private: Uses an index to get the value of a cell.
    def get_row_by_idx(idx)
      @row[idx]
    end

    # Private: Uses the key map to get the value of a cell.
    def set_row_by_map(key, value)
      begin
        @row[@key_map[key].index] = value
      rescue => err
        raise UnknownVariableKeyError, "#{key} not defined" unless @key_map.has_key? key
        raise err
      end
    end

    # Private: Uses an index to get the value of a cell.
    def set_row_by_idx(idx, value)
      @row[idx] = value
    end
  end
end
