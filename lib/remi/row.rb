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
    def_delegators :@row, :[], :length

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
    def initialize(row = [], last_row: false, row_number: nil)
      @row = row
      @last_row = last_row
      @row_number = row_number
    end

    # Public: Returns the array portion of the row.
    #
    # Returns an array.
    def to_a
      @row
    end
  end
end
