module Remi
  module Interfaces

    # Public: The canonical interface is an interface with a file on the local system.
    # Data is written to the file by serializing the row objects using MessagePack and
    # then compressed to save space and IO.  Each data set is a collection of two files.
    # One is a header that stores all of the metadata about a data set and the other
    # is a detail file that stores all of the data.
    class ShellInterface

      # Public: Initializes a ShellInterface.
      #
      # data_lib      - An instance of a DataLib object that this data set belongs to.
      # data_set_name - The name of the data set, which translates to the name of the file created.
      def initialize(data_lib, data_set_name)
        @data_lib = data_lib
        @data_set_name = data_set_name

        @prev_read = nil
        @eof_flag = false
      end

      # Public: Opens the file for writing.
      #
      # Returns nothing.
      def open_for_write
      end

      # Public: Opens the file for reading.
      #
      # Returns nothing.
      def open_for_read
      end


      # Public: Reads and returns the data set metadata.
      def read_metadata
        { :variable_set => nil }
      end

      # Public: Write the data set metadata.
      def write_metadata(variable_set: nil)
      end


      # Public: Reads a row from the file into the active row.  For the shell interface,
      # it just creates a new empty row.
      #
      # key_map - Uses the specified key_map (VariableSet) when creating
      #           the active row.
      #
      # Returns a Row instance.
      def read_row(key_map: nil)
        Row.new([nil]*key_map.size, last_row: false, key_map: key_map)
      end

      # Public: Writes a row to the data file.
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
        false
      end

      # Public: Creates a new file represending an empty data set.
      #
      # Returns nothing.
      def create_empty_data_set
      end

      # Public: Deletes the header and data files.
      #
      # Returns nothing.
      def delete
      end
    end
  end
end
