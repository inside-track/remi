module Remi

  # Public: A RowSet is a collection of row objects.  Row objects are basically
  # arrays, with some additional metadata.  A RowSet consists of a current row,
  # and a number of leading or lagging rows (usually just 1 lead and 1 lag row).
  # The lead and lag rows are most helpful in calculating by groups, which indicate
  # whether a row is the first, last, or interior member of a by group.
  #
  # RowSets are indexed using integers.  A DataSet is used to tie together
  # variable names with the RowSet indexes.
  class RowSet

    class RowDoesNotExistError < StandardError; end

    # Public: Gets the number of lag rows in use.
    attr_reader :lag_rows

    # Public: Gets the number of lead rows in use.
    attr_reader :lead_rows

    # Public: Gets the key map in use.
    attr_reader :key_map


    # Public: Initializes a RowSet.
    #
    # lag_rows  - The number of rows to retain in memory after the current row
    #             is processed.
    # lead_rows - The number of rows to retain in memory that preceed the
    #             current row.
    # by_groups - An array that indicates which row indexes form a by group.
    # key_map   - Provides a mapping between named keys and the index of the row array.
    #             Must return the index via key_map[:key].index (like a VariableWithIndex).
    def initialize(lag_rows: 1, lead_rows: 1, by_groups: [], key_map: nil)
      @rows = {}
      @lead_rows = lead_rows
      @lag_rows = lag_rows
      @key_map = key_map
      initialize_rows

      @by_groups = Array(by_groups)
      @by_first = {}
      @by_last = {}
      @has_by_groups = @by_groups.length > 0
    end

    # Public: Add a Row object to the rowset.  When a Row is added to the rowset,
    # all rows are shifted back by one step (so the current row become the previous
    # row, etc.).  The added Row is added at the maximum lead_row position.
    #
    # row - A row object that is to be added to the RowSet.
    #
    # Returns nothing.
    def add(row)
      row.row_number ||= (@rows[@lead_rows].row_number || 0) + 1
      (-@lag_rows).upto(@lead_rows - 1).each do |i|
        @rows[i] = @rows[i+1]
      end
      @rows[@lead_rows] = row

      update_by_groups if has_by_groups?
    end

    # Public: Array accessor for the current row of the RowSet.
    #
    # key - A name or integer used to get the value of a particular element of the row.
    #       If a key_map is given, a name (symbol) is required.  Otherwise, the
    #       key must be an integer.
    #
    # Returns the value of the current Row at the index given.
    def [](key)
      @rows[0][key]
    end


    # Public: Returns the current Row.
    def curr
      @rows[0]
    end

    # Public: Returns the previous Row.
    def prev
      lag(1)
    end

    # Public: Returns the next Row.
    def next
      lead(1)
    end

    # Public: Returns the Row that is n steps behind the current row.
    #
    # n - Number of lag steps.
    #
    # Returns a Row object.
    def lag(n)
      raise RowDoesNotExistError unless @rows.has_key? -n
      @rows[-n]
    end

    # Public: Returns the Row that is n steps ahead of the current row.
    #
    # n - Number of lead steps.
    #
    # Returns a Row object.
    def lead(n)
      raise RowDoesNotExistError unless @rows.has_key? n
      @rows[n]
    end

    # Public: Returns a boolean indicating whether the RowSet was initialized with
    # by groups.
    def has_by_groups?
      @has_by_groups
    end

    # Public: Updated the first/last indicators of by groups.
    #
    # Returns nothing.
    def update_by_groups
      parent_first = false
      parent_last = false
      @by_groups.each do |grp|
        @by_first[grp] = ((self[grp] != self.prev[grp]) or parent_first)
        @by_last[grp]  = ((self[grp] != self.next[grp]) or parent_last or self.curr.last_row)

        parent_first = @by_first[grp]
        parent_last = @by_last[grp]
      end
    end

    # Public: Used to determine if the given index is the first in a group
    # of similar values.
    #
    # key - The name (or index) of the Row object to check to see if it is first in a group.
    #       (default: uses the first by group specified).
    #
    # Returns a boolean.
    def first(key = nil)
      @by_first[key || @by_groups[0]]
    end

    # Public: Used to determine if the given index is the last in a group
    # of similar values.
    #
    # key - The name (or index) of the Row object to check to see if it is last in a group.
    #       (default: uses the first by group specified).
    #
    # Returns a boolean.
    def last(key = nil)
      @by_last[key || @by_groups[0]]
    end


    private

    # Private: Initializes all of the lead, current, and lag rows with empty
    # Row objects.
    def initialize_rows
      (-@lag_rows).upto(@lead_rows).each do |i|
        @rows[i] = Row.new(Array.new, key_map: @key_map)
      end
    end

    # Private: Returns true if a key map is present.
    def key_map?
      !@key_map.nil?
    end
  end
end
