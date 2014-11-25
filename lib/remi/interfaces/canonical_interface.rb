module Remi
  module Interfaces

    class DataSetAlreadyExists < StandardError; end
    class UnknownDataSet < StandardError; end

    # Public: The canonical interface is an interface with a file on the local system.
    # Data is written to the file by serializing the row objects using MessagePack and
    # then compressed to save space and IO.  Each data set is a collection of two files.
    # One is a header that stores all of the metadata about a data set and the other
    # is a detail file that stores all of the data.
    class CanonicalInterface

      # Public: Initializes a CanonicalInterface.
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
        @header_file = Zlib::GzipWriter.new(File.open(header_file_full_path,"w"))
        @header_stream = MessagePack::Packer.new(@header_file)

        @data_file = Zlib::GzipWriter.new(File.open(data_file_full_path,"w"))
        @data_stream = MessagePack::Packer.new(@data_file)
      end

      # Public: Opens the file for reading.
      #
      # Returns nothing.
      def open_for_read
        @header_file = Zlib::GzipReader.new(File.open(header_file_full_path,"r"))
        @header_stream = MessagePack::Unpacker.new(@header_file)

        @data_file = Zlib::GzipReader.new(File.open(data_file_full_path,"r"))
        @data_stream = MessagePack::Unpacker.new(@data_file)
      end

      # Public: Returns the full path to the header file.
      def header_file_full_path
        component_file_full_path('hgz')
      end

      # Public: Returns the full path to the data file.
      def data_file_full_path
        component_file_full_path('rgz')
      end

      # Public: Returns the full path to either the header or data file.
      def component_file_full_path(component)
        File.join(@data_lib.dir_name,"#{@data_set_name}.#{component}")
      end

      # Public: Converts all of the header information to a hash.
      def read_header
        symbolize_keys(@header_stream.read)
      end

      # Public: Writes all of the header information to the header file.
      def write_header(header)
        @header_stream.write(header).flush
      end

      # Public: Reads a row from the file into the active row.
      #
      # key_map - Uses the specified key_map (VariableSet) when creating
      #           the active row.
      #
      # Returns a Row instance.
      def read_row(key_map: nil)
        # Need to read ahead by one record in order to get EOF flag
        @prev_read ||= @data_stream.read
        begin
          this_read = @data_stream.read
        rescue EOFError
          @eof_flag = true
        end
        row = Row.new(@prev_read, last_row: @eof_flag, key_map: key_map)
        @prev_read = this_read
        row
      end

      # Public: Writes a row to the data file.
      #
      # row - A Row instance to be written.
      #
      # Returns nothing.
      def write_row(row)
        @data_stream.write(row.to_a).flush
      end

      # Public: Closes the header and data files.
      #
      # Returns nothing.
      def close
        @data_file.close unless @data_file.closed?
        @header_file.close unless @header_file.closed?
      end

      # Public: Returns true if the file representing the data set exists.
      def data_set_exists?
        Pathname.new(header_file_full_path).exist?
      end

      # Public: Creates a new file represending an empty data set.
      #
      # Returns nothing.
      def create_empty_data_set
        open_for_write
        close
      end

      # Public: Deletes the header and data files.
      #
      # Returns nothing.
      def delete
        File.delete(header_file_full_path)
        File.delete(data_file_full_path)
      end
    end
  end
end
