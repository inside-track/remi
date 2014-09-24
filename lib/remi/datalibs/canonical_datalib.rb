module Remi
  module Datalibs
    class CanonicalDatalib

      attr_accessor :dir_name

      def initialize(dir_name)
        @dir_name = dir_name
        @directory = Pathname.new(@dir_name)
      end

      def datasets
        # use this, but strip out the extension/path
        Dir[File.join(@dir_name, "*.hgz")]
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
      def build(dataset_name)
        interface = Interfaces::CanonicalInterface.new(self, dataset_name)

        raise Interfaces::DatasetAlreadyExists if interface.dataset_exists?
        
        interface.create_empty_dataset
        Dataset.new(dataset_name, interface)
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
        
      end

    end
  end
end
