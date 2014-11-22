module Remi
  module Datalibs
    class CanonicalDatalib

      attr_accessor :dir_name

      # Public: Initialiazes a CanonicalDatalib.
      #
      # dir_name - The directory name that the canonical datalib points to.
      def initialize(dir_name)
        @dir_name = dir_name
        @directory = Pathname.new(@dir_name)

        @dataset_list = {}
        build_dataset_list
      end

      # Public: Returns an array of datasets names as symbols.
      #
      # Returns an enumator that iterates over datasets contained in library.
      def datasets
        build_dataset_list
        @dataset_list.values
      end

      # Public: Returns the number of datasets currently defined in the library.
      #
      # Returns a number.
      def length
        datasets.length
      end

      # Public: Used to initialize a new dataset in a library.  This will
      # create a new empty dataset in directory specified by the library.
      # If a dataset already exists, it raises an error.
      #
      # dataset_name - Name of the dataset to initialize.
      #
      # Returns a Dataset.
      def build(dataset_name)
        raise Interfaces::DatasetAlreadyExists if interface(dataset_name).dataset_exists?
        build!(dataset_name)
      end

      # Public: Used to initialize a new dataset in a library.  This will
      # create a new empty dataset in directory specified by the library.
      # If a dataset already exists, it will be overwritten.
      #
      # dataset_name - Name of the dataset to initialize.
      #
      # Returns a Dataset.
      def build!(dataset_name)
        interface(dataset_name).create_empty_dataset
        @dataset_list[dataset_name] = Dataset.new(dataset_name, interface(dataset_name))
      end



      # Public: Array accessor for the Datalib used to retrieve a Dataset.
      #
      # dataset_name - Name of the dataset in the library.
      #
      # Returns the Dataset object specified by the name or nil if one does not exist.
      def [](dataset_name)
        @dataset_list[dataset_name]
      end


      # Public: Deletes a dataset from the libary.
      #
      # dataset_name - The name of the dataset to delete.
      #
      # Returns nothing.
      def delete(dataset_name)
        @dataset_list[dataset_name].delete
        @dataset_list.delete(dataset_name)
      end

      private

      # Private: Builds a CanonicalInterface for a dataset with the specified name
      # in the current Datalib.
      #
      # dataset_name - Name of the dataset to build the interface for.
      #
      # Returns a CanonicalInterface.
      def interface(dataset_name)
        Interfaces::CanonicalInterface.new(self, dataset_name)
      end

      # Private: Finds all of the datasets available in the directory.
      #
      # Returns the dataset list and populates instance variable.
      def build_dataset_list
        existing_datasets = {}

        Dir[File.join(@dir_name, "*.hgz")].collect do |filename|
          dataset_name = Pathname.new(filename).sub_ext('').basename.to_s.to_sym

          if @dataset_list.has_key? dataset_name
            existing_datasets[dataset_name] = @dataset_list[dataset_name]
          else
            existing_datasets[dataset_name] = Dataset.new(dataset_name, interface(dataset_name), mode: 'r')
          end
        end

        @dataset_list = existing_datasets
      end

    end
  end
end
