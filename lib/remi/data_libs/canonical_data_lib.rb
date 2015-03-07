module Remi
  module DataLibs

    # Public: The canonical data library is a collection of data sets created using
    # the canonical interface on the local filesystem.
    class CanonicalDataLib < BasicDataLib

      attr_accessor :dir_name

      # Public: Initialiazes a CanonicalDataLib.
      #
      # dir_name - The directory name that the canonical data lib points to.
      def initialize(dir_name: dir_name)
        super

        @dir_name = dir_name
        @directory = Pathname.new(@dir_name)

        update
      end

      # Public: Finds all of the data sets available in the directory.
      #
      # Returns the data set list and populates instance variable.
      def update
        existing_data_sets = {}

        Dir[File.join(@dir_name, "*.hgz")].collect do |filename|
          data_set_name = Pathname.new(filename).sub_ext('').basename.to_s.to_sym

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

      # Private: Builds a CanonicalInterface for a data set with the specified name
      # in the current DataLib.
      #
      # data_set_name - Name of the data set to build the interface for.
      #
      # Returns a CanonicalInterface.
      def interface(data_set_name)
        Interfaces::CanonicalInterface.new(self, data_set_name)
      end
    end
  end
end
