module Remi
  module Interfaces

    class DatasetAlreadyExists < StandardError; end
    class UnknownDataset < StandardError; end

    class CanonicalInterface
      def initialize(datalib, dataset_name)
        @datalib = datalib
        @dataset_name = dataset_name

        @prev_read = nil
        @eof_flag = false
      end

      def open_for_write
        @header_file = Zlib::GzipWriter.new(File.open(header_file_full_path,"w"))
        @header_stream = MessagePack::Packer.new(@header_file)

        @data_file = Zlib::GzipWriter.new(File.open(data_file_full_path,"w"))
        @data_stream = MessagePack::Packer.new(@data_file)
      end

      def open_for_read
        @header_file = Zlib::GzipReader.new(File.open(header_file_full_path,"r"))
        @header_stream = MessagePack::Unpacker.new(@header_file)

        @data_file = Zlib::GzipReader.new(File.open(data_file_full_path,"r"))
        @data_stream = MessagePack::Unpacker.new(@data_file)
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
        symbolize_keys(@header_stream.read)
      end

      def write_header(header)
        @header_stream.write(header).flush
      end

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

      def write_row(row)
        @data_stream.write(row.to_a).flush
      end

      def close
        @data_file.close unless @data_file.closed?
        @header_file.close unless @header_file.closed?
      end

      def dataset_exists?
        Pathname.new(header_file_full_path).exist?
      end

      def create_empty_dataset
        open_for_write
        close
      end

      def delete
        File.delete(header_file_full_path)
        File.delete(data_file_full_path)
      end

    end
  end
end
