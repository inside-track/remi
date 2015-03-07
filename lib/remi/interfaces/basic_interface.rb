module Remi
  module Interfaces

    class DataSetAlreadyExists < StandardError; end
    class UnknownDataSet < StandardError; end

    # Public: This class is used to register when the create_empty_dataset method
    # has been called for a particular data set in a particular basic data library.
    class BasicInterfaceRegister
      @created_basic_interface = {}
      class << self
        attr_accessor :created_basic_interface

        def [](data_lib)
          created_basic_interface[data_lib] ||= {}
        end
      end
    end


    # Public: The basic interface is the template for building interfaces.  All
    # interfaces should inherit from this class.  Interfaces define how data
    # is written to and read from the source.  For the basic interface, data writes
    # do nothing and data reads return empty rows.
    class BasicInterface

      # Public: Initializes a BasicInterface.
      #
      # data_lib      - An instance of a DataLib object that this data set belongs to.
      # data_set_name - The name of the data set, which translates to the name of the file created.
      def initialize(data_lib, data_set_name, *args)
        @data_lib = data_lib
        @data_set_name = data_set_name

        @eof_flag = false
      end

      # Public: Gets the end of file flag.
      #      attr_reader :eof_flag
      def eof_flag
        @eof_flag
      end


      # Public: Opens the data source for writing.
      #
      # Returns nothing.
      def open_for_write
      end

      # Public: Opens the data source for reading.
      #
      # Returns nothing.
      def open_for_read
      end


      # Public: Reads metadata from the source and returns the data set metadata.
      def read_metadata
        { :variable_set => nil }
      end

      # Public: Write the data set metadata to the data source.
      def write_metadata(variable_set: nil)
      end


      # Public: Reads a row from the data source into the active row.
      # For the basic interface, it just creates a new empty row.
      #
      # key_map - Uses the specified key_map (VariableSet) when creating
      #           the active row.
      #
      # Returns a Row instance.
      def read_row(key_map: nil)
        Row.new([nil]*key_map.size, last_row: false, key_map: key_map)
      end

      # Public: Writes a row to the data source.  For the basic
      # interface, it does nothing.
      #
      # row - A Row instance to be written.
      #
      # Returns nothing.
      def write_row(row)
      end

      # Public: Closes the header and data files.
      #
      # Returns nothing.
      def close
      end

      # Public: Returns true if the file representing the data set exists.
      def data_set_exists?
        !BasicInterfaceRegister[@data_lib][@data_set_name].nil?
      end

      # Public: Initializes a data source by creating a placeholder.
      #
      # Returns nothing.
      def create_empty_data_set
        BasicInterfaceRegister[@data_lib][@data_set_name] = true
      end

      # Public: Deletes the data source.
      #
      # Returns nothing.
      def delete
        BasicInterfaceRegister[@data_lib].delete(@data_set_name)
      end


      private

      # Private: Sets the end of file flag.
      def eof_flag=(value)
        @eof_flag = value
      end
    end
  end
end
