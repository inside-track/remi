module Remi
  module Interfaces

    class DatasetAlreadyExists < StandardError; end
    class UnknownDataset < StandardError; end

    class CanonicalInterface
      def initialize(datalib, dataset_name)
        @datalib = datalib
        @dataset_name = dataset_name

#        create_empty_dataset unless dataset_exists?
      end

      def open_for_write
        @header_file = Zlib::GzipWriter.new(File.open(header_file_full_path,"w"))
        @header_stream = MessagePack::Packer.new(@header_file)

        @data_file = Zlib::GzipWriter.new(File.open(data_file_full_path,"w"))
        @data_stream = MessagePack::Packer.new(@data_file)
      end
      
      def header_file_full_path
        component_file_full_path('hgz')
      end

      def data_file_full_path
        component_file_full_path('rgz')
      end

      def component_file_full_path(component)
        File.join(@datalib.dir_name,"#{@dataset_name}.#{component}")
      end
      

      def read_header
      end

      def dataset_exists?
        Pathname.new(header_file_full_path).exist?
      end

      def create_empty_dataset
        open_for_write

        @data_file.close
        @header_file.close
      end

      def delete
        File.delete(header_file_full_path)
        File.delete(data_file_full_path)
      end

    end
  end
end
