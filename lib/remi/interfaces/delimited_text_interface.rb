module Remi
  module Interfaces

    # Public: The DelimitedTextInterface is an interface that can be used to read
    # and write delimited text files on the local file system.  It is basically
    # a convenient wrapper for the CSV core Ruby class that makes writing CSV files
    # as easy as writing a Remi data set.
    class DelimitedTextInterface < BasicInterface

      # Public: Initializes a DelimitedTextInterface.
      #
      # data_lib      - An instance of a DataLib object that this data set belongs to.
      # data_set_name - The name of the data set, which translates to the name of the file created.
      def initialize(data_lib, data_set_name)
        super(data_lib, data_set_name)
      end

      # Public: Gets the data file object
      attr_reader :data_file

      # Public: Opens the file for writing.
      #
      # Returns nothing.
      def open_for_write
        self.eof_flag = false
        open_data_for_write
      end

      # Public: Opens the file for reading.
      #
      # Returns nothing.
      def open_for_read
        self.eof_flag = false
        open_data_for_read
      end

      # Public: Returns the full path to the data file.
      def data_file_full_path
        File.join(@data_lib.dir_name,"#{@data_set_name}")
      end


      # Public: Reads and returns the data set metadata
      def read_metadata
        { :variable_set => read_variable_set }
      end

      # Public: Write the delimited text header.
      def write_metadata(variable_set: nil)
        @data_file << variable_set.keys if @data_lib.csv_opt[:headers]
      end

      # Public: Reads a row from the file into the active row.
      #
      # key_map - Uses the specified key_map (VariableSet) when creating
      #           the active row.
      #
      # Returns a Row instance.
      def read_row(key_map: nil)
        # Need to read ahead by one record in order to get EOF flag
        @prev_read ||= @data_stream.readline

        self.eof_flag = @data_stream.eof?
        this_read = @data_stream.readline

        if @data_lib.csv_opt[:headers] && @data_lib.header_as_variables
          row_array = @prev_read
        else
          varidx_to_col = []
          key_map.each do |v,m|
            if m.meta.has_key?(:csv_opt) && m.meta[:csv_opt].has_key?(:col)
              col = m.meta[:csv_opt][:col] - 1
              varidx_to_col[m.index] = col if col < @prev_read.size
            end
          end

          row_array = key_map.map.with_index { |v,i| varidx_to_col[i] && @prev_read[varidx_to_col[i]] }
        end


        row = Row.new(row_array, last_row: eof_flag, key_map: key_map)
        @prev_read = this_read

        row
      end

      # Public: Writes a row to the data file.
      #
      # row - A Row instance to be written.
      #
      # Returns nothing.
      def write_row(row)
        @data_stream << row.to_a
      end

      # Public: Closes the header and data files.
      #
      # Returns nothing.
      def close
        close_data_file
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




      private

      # Private: Opens the data file for writing.
      def open_data_for_write
        @data_file = CSV.open(data_file_full_path,"w+", @data_lib.csv_opt)
        @data_stream = @data_file
      end

      # Private: Opens the data file for reading.
      def open_data_for_read
        @data_file = CSV.open(data_file_full_path,"r", @data_lib.csv_opt)
        @data_stream = @data_file
      end

      # Private: Closes the data file.
      def close_data_file
        @data_file.close unless @data_file.closed?
      end

      # Private: Reads the header row of the delimted text file and returns a variable set.
      #  (if :headers and :headers_as_variables are specified).
      def read_variable_set
        return VariableSet.new unless @data_lib.csv_opt[:headers] && @data_lib.header_as_variables

        open_data_for_read
        first_row = @data_file.readline
        headers = @data_file.headers
        close_data_file

        VariableSet.new do
          headers.each do |header|
            var header.to_sym
          end
        end
      end

    end
  end
end
