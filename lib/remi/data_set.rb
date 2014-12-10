module Remi

  # Public: The DataSet class ties together variable names and metadata attributes
  # (via a VariableSet), the data values referenced by a variable (via a RowSet), and
  # the method by which data is read and written to the storage method (via an Interface).
  class DataSet
    extend Forwardable

    def_delegators :@interface, :open_for_write, :open_for_read, :close, :delete
    def_delegators :@active_row, :row_number, :last_row

    # Public: DataSet initializer.
    #
    # data_set_name - The name (symbol) associated with the data set.
    # interface     - An instance of the Interface class used to interact with the physical data.
    def initialize(data_set_name, interface)
      @name = data_set_name
      @interface = interface

      @variable_set = VariableSet.new
      @active_row = Row.new(key_map: @variable_set)
    end

    # Public: Gets the VariableSet associated with this DataSet.
    attr_reader :variable_set

    # Public: Opens a dataset for read access.
    #
    # lead_rows - Maximum number of rows to read ahead.
    # lag_rows  - Maximum number or rows to retain in memory after reading.
    # by_group  - An array containing the variable names (symbols) that define a by-group.
    #
    # Returns nothing.
    def open_for_read(lead_rows: 1, lag_rows: 1, by_groups: nil)
      @mode = 'r'
      @lead_rows = lead_rows
      @lag_rows = lag_rows
      @lag_offset = 0
      @by_groups = by_groups

      @interface.open_for_read
      @row_set = RowSet.new(lag_rows: lag_rows, lead_rows: lead_rows, by_groups: by_groups)
    end

    # Public: Opens a dataset for write access.
    #
    # lag_rows  - Maximum number or rows to retain in memory after writing.
    #
    # Returns nothing.
    def open_for_write(lag_rows: 1)
      @mode = 'r'
      @lead_rows = 0
      @lag_rows = lag_rows
      @lag_offset = 1

      @interface.open_for_write
      @metadata_written = false
      @row_set = RowSet.new(lag_rows: lag_rows, lead_rows: 0)
    end

    # Public: Returns true if the dataset is open for reading.
    def open_for_read?
      @mode == 'r'
    end

    # Public: Returns true if the dataset is open for writing.
    def open_for_write?
      @mode == 'w'
    end

    # Public: Used to define variables associated with the dataset.
    # New variables can be added as an array argument or defined
    # in a block using VariableSet#modify.
    #
    # vars  - An array of variables to add to the dataset.
    # block - A block that has access to the VariableSet modify methods.
    #
    # Returns nothing.
    def define_variables(vars = [], &block)
      @variable_set.add_vars(vars)
      @variable_set.modify(&block) if block_given?
    end

    # Public: Array accessor setter method for the values of a dataset variable.
    #
    # key   - The name (symbol) of the variable.
    # value - The new value of the variable.
    #
    # Returns the value set.
    def []=(key, value)
      @active_row[key] = value
    end

    # Public: Array accessor that gets the value of the variable.
    #
    # key - The name (symbol) of the variable.
    #
    # Returns the value of the variable.
    def [](key)
      @active_row[key]
    end

    # Public: Used to get values from the row that is N rows prior to
    # the current active row.  The maximum lag is set when the dataset
    # is opened for read/write.
    #
    # n - The number of rows to go back to.
    #
    # Examples
    #   mydataset.lag(2)[:myvariable] # Returns the value of :myvariable that was effective 2 rows prior to the active row.
    #
    # Returns a Row instance.
    def lag(n)
      # Note: Using the array accessors gives back the active row, which
      # is either the row just read, or the row that is yet-to-be
      # written.  When a row is written, it is written to the 0 position
      # of the RowSet.  When we're writting data, we want to think of
      # this 0 position as the previous row, or one that has a lag of
      # n=1.  We use the lag_offset here to enable this convention.
      return lead(n) if n <= 0
      @row_set.lag(n - @lag_offset)
    end

    # Public: Used to get values from upcoming rows prior to them becomming the active
    # row.  This is only available for reading datasets.  The maximum lead is set
    # when the dataset is opened for writing.
    #
    # n - The number of rows to read ahead
    #
    # Examples
    #   mydataset.lead(1)[:myvariable] # Returns the value of :myvariable that will be in the next row.
    #
    # Returns a Row instance.
    def lead(n)
      return @active_row if n == 0
      @row_set.lead(n)
    end


    def read_data_set_metadata
      metadata = @interface.read_metadata
      @variable_set = metadata[:variable_set]
    end


    # Public: Writes the active row to the data source.
    #
    # Returns nothing.
    def write_row
      @interface.write_metadata(variable_set: @variable_set) unless @metadata_written
      @metadata_written = true

      @row_set.add(Row.new(@active_row.to_a, key_map: @variable_set))
      @interface.write_row(@active_row)
    end

    # Public: Reads the next row of data from the data source into the active row.
    #
    # Returns nothing.
    def read_row
      @active_row = @interface.read_row(key_map: @variable_set)
      @row_set.add(@active_row)
    end

  end
end
