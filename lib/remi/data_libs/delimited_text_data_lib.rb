module Remi
  module DataLibs

    # Public: The delimisted text data library is a collection of
    # data sets created using the delimited text interface on the local filesystem.
    # The collection of files can be specified using a regex.  All of the delimited
    # text files in the library must use the same csv read options.  So things like
    # the delimiter, and whether header records are present must be the same for each
    # file in the library.  Of course, multiple libraries that point to the same file
    # but with different options can be specified if this is a potential issue.
    class DelimitedTextDataLib < BasicDataLib

      attr_accessor :dir_name
      attr_accessor :file_pattern
      attr_accessor :csv_opt
      attr_accessor :header_as_variables

      DEFAULT_CSV_OPT = {
        headers: true,
        return_headers: false,
        write_headers: true,
        col_sep: ',',
        header_converters: :symbol
      }

      # Public: Initialiazes a DelimitedTextDataLib.
      #
      # dir_name            - The directory name that the delimited text files are found in.
      # file_pattern        - A regular expression that includes all files in the directory
      #                       matching the regular expression (default: all files - /.*/).
      # header_as_variables - Specifies whether the header record of the csv file should
      #                       be interpreted as the name of the data set variable (as a symbol).
      #                       (default: false)
      # csv_opt             - A hash containing options that are passed to the CSV.new
      #                       core class option (default: DEFAULT_CSV_OPT)
      def initialize(dir_name:, file_pattern: /.*/, header_as_variables: false, csv_opt: DEFAULT_CSV_OPT)
        super

        @dir_name = dir_name
        @directory = Pathname.new(@dir_name)
        @file_pattern = file_pattern
        @header_as_variables = header_as_variables
        @csv_opt = DEFAULT_CSV_OPT.merge(csv_opt)


        update
      end

      # Public: Finds all of the files available in the directory matching the pattern.
      #
      # Returns the data set list and populates instance variable.
      def update
        existing_data_sets = {}

        Dir["#{@dir_name}/*"].select { |f| Pathname.new(f).basename.to_s.match(file_pattern) }.each do |filename|
          data_set_name = Pathname.new(filename).basename.to_s.to_sym

          if library.has_key? data_set_name
            existing_data_sets[data_set_name] = library[data_set_name]
          else
            ds = DataSet.new(data_set_name, interface(data_set_name))
            existing_data_sets[data_set_name] = ds
            ds.read_data_set_metadata
          end
        end

        self.library = existing_data_sets
      end


      private

      # Private: Builds a DelimitedTextInterface for a data set with the specified name
      # in the current DataLib.
      #
      # data_set_name - Name of the data set to build the interface for.
      #
      # Returns a DelimitedTextInterface.
      def interface(data_set_name)
        Interfaces::DelimitedTextInterface.new(self, data_set_name)
      end
    end
  end
end
