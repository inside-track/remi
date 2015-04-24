module Remi

  # Public: The DataSet class ties together variable names and metadata attributes
  # (via a VariableSet), the data values referenced by a variable (via a RowSet), and
  # the method by which data is read and written to the storage method (via an Interface).
  class DataSet
    extend Forwardable

    def_delegators :@interface, :open_for_write, :open_for_read, :close, :delete
    def_delegators :@active_row, :row_number, :last_row

    class UnknownByGroupVariableError < StandardError; end

    # Public: DataSet initializer.
    #
    # data_set_name - The name (symbol) associated with the data set.
    # interface     - An instance of the Interface class used to interact with the physical data.
    def initialize(data_set_name, interface)
      @name = data_set_name
      @interface = interface

      @variable_set = VariableSet.new
      @active_row = Row.new(key_map: @variable_set).clear
    end

    # Public: Gets the VariableSet associated with this DataSet.
    attr_reader :variable_set

    # Public: Gets the name of the dataset.
    attr_reader :name

    # Public: Gets the interface used to create the data set.
    attr_reader :interface

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
      @by_groups = Array(by_groups)
      @active_row = Row.new(key_map: @variable_set)

      validate_by_group_variables unless @by_groups.empty?
      @interface.open_for_read
      @row_set = RowSet.new(lag_rows: lag_rows, lead_rows: lead_rows, by_groups: Array(by_groups), key_map: @variable_set)
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
      @active_row = Row.new(key_map: @variable_set)

      @interface.open_for_write
      @metadata_written = false
      @row_set = RowSet.new(lag_rows: lag_rows, lead_rows: 0, key_map: @variable_set)
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
    def define_variables(*vars, &block)
      @variable_set.add_vars(*vars)
      @variable_set.modify(&block) if block_given?

      @interface.set_key_map @variable_set
    end

    # Public: Array accessor setter method for the values of a dataset variable.
    #
    # keys  - The names (symbols) of the variable.
    # value - The new value of the variable.  If a data set is given as the value,
    #         then the values are set to the values of the shared keys.
    #
    # Returns the value.
    def []=(*keys, value)
      if value.is_a?(DataSet)
        value.variable_set.keys.each do |target_key|
          @active_row[target_key] = value[target_key] if (@variable_set.has_key?(target_key) && (keys.size == 0 || keys.include?(target_key)))
        end
      elsif value.is_a?(Array)
        (keys.size > 0 ? keys : @variable_set.keys).each do |key|
          @active_row[key] = value.shift
        end
      else
        @active_row[*keys] = value
      end
    end

    # Public: Array accessor that gets the value of the variable.
    #
    # keys - The names (symbol) of the variable.
    #
    # Returns the value of the variable or an array of values if multiple keys are used as an argument.
    def [](*keys)
      return @active_row[*keys] if keys.size == 1
      return @variable_set.collect { |k| @active_row[k] } if keys.size == 0
      keys.collect { |k| @active_row[k] }
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


    def first(key = nil)
      @row_set.first(key)
    end

    def last(key = nil)
      @row_set.last(key)
    end

    # Public: Converts the active row to an array.
    #
    # Returns an array.
    def row_to_a
      @active_row.to_a
    end


    # Public: Writes the active row to the data source.
    #
    # Returns nothing.
    def write_row
      @interface.write_metadata(variable_set: @variable_set) unless @metadata_written
      @metadata_written = true

      @row_set.add(@active_row)
      @interface.write_row(@active_row)
    end

    # Public: Reads the next row of data from the data source into the active row.
    #
    # Returns nothing.
    def read_row
      load_row_set
      @active_row = @row_set.curr
    end

    # Public: Reads the data set metadata from the interface.
    #
    # Returns nothing.
    def read_data_set_metadata
      metadata = @interface.read_metadata
      @variable_set = metadata[:variable_set]
    end




    private

    # Private: Loads a row record from the interface into the row_set.  If the
    # row_set includes lead rows, it will pre-load the row_set until the
    # current row is defined.
    #
    # Returns nothing.
    def load_row_set
      loop do
        @row_set.add(get_row_from_interface)
        break unless @row_set.curr.row_number.nil?
      end
    end

    # Private: Gets a row from the interface.  If the last record from the interface
    # has already been read, start loading the row_set with nil records.
    #
    # Returns a Row.
    def get_row_from_interface
      if @row_set.lead(@row_set.lead_rows).last_row
        Row.new(Array.new(@active_row.length), last_row: true, key_map: @variable_set)
      else
        @interface.read_row
      end
    end


    # Private: Validates whether the given by group variables exist.
    def validate_by_group_variables
      raise UnknownByGroupVariableError, "Unknown by-group variable #{@by_groups - @variable_set.keys}" unless (@by_groups - @variable_set.keys).empty?
    end
  end
end
