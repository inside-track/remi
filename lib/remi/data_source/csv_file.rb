module Remi
  module DataSource
    class CsvFile
      include DataSource

      using Remi::Refinements::Daru

      def self.default_csv_options
        CSV::DEFAULT_OPTIONS.merge({
          headers: true,
          header_converters: Remi::FieldSymbolizers[:standard],
          col_sep: ',',
          encoding: 'UTF-8',
          quote_char: '"'
        })
      end


      def initialize(fields: {}, extractor:, csv_options: {}, filename_field: nil, logger: Remi::Settings.logger)
        @fields = fields
        self.extractor = extractor
        @csv_options = self.class.default_csv_options.merge(csv_options)
        @filename_field = filename_field
        @logger = logger
      end

      attr_accessor :fields
      attr_reader   :extractor
      attr_reader   :csv_options

      def field_symbolizer
        self.class.default_csv_options[:header_converters]
      end

      def extract
        @extracted = Array(@extractor.extract)
      end

      def extracted
        @extracted || extract
      end

      def extractor=(arg)
        case arg
        when Extractor::SftpFile, Extractor::LocalFile
          @extractor = arg
        when String
          @extractor = Extractor::LocalFile.new(path: arg)
        when Regexp
          raise "Adding regex matching to local files would be easy, not done yet"
        else
          raise "Unknown extractor of type #{arg.class}: #{arg}"
        end
      end

      # Only going to support single file for now
      def source_filename
        raise "Multiple source files detected" if extracted.size > 1
        @source_filename ||= extracted.first
      end

      def first_line
        # Readline assumes \n line endings.  Strip out \r if it is a DOS file.
        @first_line ||= File.open(source_filename) do |f|
          f.readline.gsub(/\r/,'')
        end
      end

      def headers
        @headers ||= CSV.open(source_filename, 'r', source_csv_options) { |csv| csv.first }.headers
      end

      def valid_headers?
        (fields.keys - headers).empty?
      end

      def to_dataframe
        # Assumes that each file has exactly the same structure
        result_df = nil
        extracted.each_with_index do |filename, idx|
          @logger.info "Converting #{filename} to a dataframe"
          csv_df = Daru::DataFrame.from_csv filename, @csv_options

          csv_df[@filename_field] = Daru::Vector.new([filename] * csv_df.size, index: csv_df.index) if @filename_field
          if idx == 0
            result_df = csv_df
          else
            result_df = result_df.concat csv_df
          end
        end

        result_df
      end

      def df
        @dataframe ||= to_dataframe
      end
    end
  end
end
