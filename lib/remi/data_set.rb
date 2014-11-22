module Remi

  # Public:
  class DataSet
    extend Forwardable

    def_delegators :@interface, :open_for_write, :open_for_read, :close, :delete
    def_delegators :@active_row, :row_number, :last_row

    def initialize(data_set_name, interface)
      @name = data_set_name
      @interface = interface

      @variable_set = VariableSet.new
      @active_row = Row.new(key_map: @variable_set)
    end

    attr_reader :variable_set

    def open_for_read(lead_rows: 1, lag_rows: 1, by_groups: nil)
      @mode = 'r'
      @lead_rows = lead_rows
      @lag_rows = lag_rows
      @lag_offset = 0
      @by_groups = by_groups

      @interface.open_for_read
      @row_set = RowSet.new(lag_rows: lag_rows, lead_rows: lead_rows, by_groups: by_groups)
    end

    def open_for_write(lag_rows: 1)
      @mode = 'r'
      @lead_rows = 0
      @lag_rows = lag_rows
      @lag_offset = 1

      @interface.open_for_write
      @row_set = RowSet.new(lag_rows: lag_rows, lead_rows: 0)
    end

    def open_for_read?
      @mode == 'r'
    end

    def open_for_write?
      @mode == 'w'
    end

    def define_variables(vars = [], &block)
      @variable_set.add_vars(vars)
      @variable_set.modify(&block) if block_given?
    end

    def []=(key, value)
      @active_row[key] = value
    end

    def [](key)
      @active_row[key]
    end

    # Using the array accessors gives back the active row, which is either
    # the row just read, or the row that is yet-to-be written.  When a row
    # is written, it is written to the 0 position of the RowSet.  When we're
    # writting data, we want to think of this 0 position as the previous row,
    # or one that has a lag of n=1.  We use the lag_offset here to enable this
    # convention.
    def lag(n)
      return lead(n) if n <= 0
      @row_set.lag(n - @lag_offset)
    end

    def lead(n)
      return @active_row if n == 0
      @row_set.lead(n)
    end


    def write_row
      @row_set.add(Row.new(@active_row.to_a, key_map: @variable_set))
      @interface.write_row(@active_row)
    end

    def read_row
      @active_row = @interface.read_row(key_map: @variable_set)
      @row_set.add(@active_row)
    end

  end
end
