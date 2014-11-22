module Remi
  module DataLibs
    class CanonicalDataLib

      attr_accessor :dir_name

      # Public: Initialiazes a CanonicalDataLib.
      #
      # dir_name - The directory name that the canonical data lib points to.
      def initialize(dir_name)
        @dir_name = dir_name
        @directory = Pathname.new(@dir_name)

        @data_set_list = {}
        build_data_set_list
      end

      # Public: Returns an array of data set names as symbols.
      #
      # Returns an enumator that iterates over data sets contained in library.
      def data_sets
        build_data_set_list
        @data_set_list.values
      end

      # Public: Returns the number of data sets currently defined in the library.
      #
      # Returns a number.
      def length
        data_sets.length
      end

      # Public: Used to initialize a new data set in a library.  This will
      # create a new empty data set in directory specified by the library.
      # If a data set already exists, it raises an error.
      #
      # data_set_name - Name of the data set to initialize.
      #
      # Returns a DataSet.
      def build(data_set_name)
        raise Interfaces::DataSetAlreadyExists if interface(data_set_name).data_set_exists?
        build!(data_set_name)
      end

      # Public: Used to initialize a new data set in a library.  This will
      # create a new empty data set in directory specified by the library.
      # If a data set already exists, it will be overwritten.
      #
      # data_set_name - Name of the data set to initialize.
      #
      # Returns a DataSet.
      def build!(data_set_name)
        interface(data_set_name).create_empty_data_set
        @data_set_list[data_set_name] = DataSet.new(data_set_name, interface(data_set_name))
      end



      # Public: Array accessor for the DataLib used to retrieve a DataSet.
      #
      # data_set_name - Name of the data set in the library.
      #
      # Returns the DataSet object specified by the name or nil if one does not exist.
      def [](data_set_name)
        @data_set_list[data_set_name]
      end


      # Public: Deletes a data set from the libary.
      #
      # data_set_name - The name of the data set to delete.
      #
      # Returns nothing.
      def delete(data_set_name)
        @data_set_list[data_set_name].delete
        @data_set_list.delete(data_set_name)
      end

      private

      # Private: Builds a CanonicalInterface for a data set with the specified name
      # in the current DataLib.
      #
      # data_set_name - Name of the data set to build the interface for.
      #
      # Returns a CanonicalInterface.
      def interface(data_set_name)
        Interfaces::CanonicalInterface.new(self, data_set_name)
      end

      # Private: Finds all of the data sets available in the directory.
      #
      # Returns the data set list and populates instance variable.
      def build_data_set_list
        existing_data_sets = {}

        Dir[File.join(@dir_name, "*.hgz")].collect do |filename|
          data_set_name = Pathname.new(filename).sub_ext('').basename.to_s.to_sym

          if @data_set_list.has_key? data_set_name
            existing_data_sets[data_set_name] = @data_set_list[data_set_name]
          else
            existing_data_sets[data_set_name] = DataSet.new(data_set_name, interface(data_set_name))
          end
        end

        @data_set_list = existing_data_sets
      end

    end
  end
end
