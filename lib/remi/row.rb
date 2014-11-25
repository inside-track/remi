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
    def_delegators :@row, :each, :length

    # Public: Gets/sets the end of file flag.
    attr_accessor :last_row

    # Public: Gets/sets the row number.
    attr_accessor :row_number

    # Public: Initialize a new row.
    #
    # row        - An array of data representing the row.
    # last_row   - A flag indicating whether this is the last row in a data
    #              stream (default: false)
    # row_number - An integer indicating the row number of the data stream (default: nil).
    # key_map    - Provides a mapping between named keys and the index of the row array.
    #              Must return the index via key_map[:key].index (like a VariableWithIndex).
    def initialize(row = [], last_row: false, row_number: nil, key_map: nil)
      @row = row
      @last_row = last_row
      @row_number = row_number
      @key_map = key_map
    end

    # Public: Array accessor method to get a particular value from the row.
    #
    # key - A name or integer used to get the value of a particular element of the row.
    #       If a key_map is given, a name (symbol) is required.  Otherwise, the
    #       key must be an integer.
    #
    # Returns the value of the row element.
    def [](key)
      key_map? ? get_row_by_map(key) : get_row_by_idx(key)
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
      key_map? ? set_row_by_map(key, value) : set_row_by_idx(key, value)
    end


    # Public: Returns the array portion of the row.
    #
    # Returns an array.
    def to_a
      Array.new @row
    end


    private

    # Private: Returns true if a key map is present.
    def key_map?
      !@key_map.nil?
    end

    # Private: Uses the key map to get the value of a cell.
    def get_row_by_map(key)
      @row[@key_map[key].index]
    end

    # Private: Uses an index to get the value of a cell.
    def get_row_by_idx(idx)
      @row[idx]
    end

    # Private: Uses the key map to get the value of a cell.
    def set_row_by_map(key, value)
      @row[@key_map[key].index] = value
    end

    # Private: Uses an index to get the value of a cell.
    def set_row_by_idx(idx, value)
      @row[idx] = value
    end
  end
end
