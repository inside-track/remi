module Remi
  module Datalibs
    class CanonicalDatalib

      attr_accessor :dir_name

      def initialize(dir_name)
        @dir_name = dir_name
        @directory = Pathname.new(@dir_name)
      end

      # Public: 
      def datasets
        Dir[File.join(@dir_name, "*.hgz")].collect do |filename|
          Pathname.new(filename).sub_ext('').basename.to_s.to_sym
        end
      end

      def length
        datasets.length
      end

      # I don't like create because it implies that a file should
      # be written or a schema created.
      # Here, we really just need it to return an instance of the dataset,
      # whether it is persisted to database or file or not.
      # Which is kind of why I like 'new'.  Maybe 'new_dataset'?

      # How about 'build' - in that it sets up the space for a datset to
      # be created, but does not actually create it at the time

      # But it might be ok to create something at this point too.
      # For datasets, it could create empty placeholder files that
      # get overwritten when the datset it written to.  For databases,
      # we could require that the schema be defined at build time
      # and only defined columns end up getting persisted.

      # should return a new dataset instance that points to a Directory interface


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
        Dataset.new(dataset_name, interface(dataset_name))
      end



      # should return an existing dataset reference
      # error if the dataset does not exist
      def [](dataset_name)
        interface = Interfaces::CanonicalInterface.new(self, dataset_name)

        raise Interfaces::UnknownDataset unless interface.dataset_exists?

        # lookup the hgz file with the name dataset and return a dataset object
        # using the Directory interface.
        Dataset.new(dataset_name, interface(dataset_name))
      end

      private

      def interface(dataset_name)
        Interfaces::CanonicalInterface.new(self, dataset_name)        
      end

    end
  end
end
