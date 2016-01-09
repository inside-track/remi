module Remi
  module DataSource
    class CsvFile
      include DataSource

      def self.default_csv_options
        CSV::DEFAULT_OPTIONS.merge({
          headers: true,
          header_converters: Remi::FieldSymbolizers[:standard],
          col_sep: ',',
          encoding: 'UTF-8',
          quote_char: '"'
        })
      end


      def initialize(fields: {}, extractor:, csv_options: {}, logger: Remi::Settings.logger)
        @fields = fields
        self.extractor = extractor
        @csv_options = self.class.default_csv_options.merge(csv_options)
        @logger = logger
      end

      attr_accessor :fields
      attr_reader   :extractor
      attr_reader   :csv_options

      def field_symbolizer
        self.class.default_csv_options[:header_converters]
      end

      def extract
        Array(@extractor.extract).tap { |x| raise "Multiple files not supported" if x.size > 1 }
      end

      def extractor=(arg)
        case arg
        when Extractor::SftpFile, Extractor::LocalFile
          @extractor = arg
        when String
          @extractor = Extractor::LocalFile.new(arg)
        when Regexp
          raise "Adding regex matching to local files would be easy, not done yet"
        else
          raise "Unknown extractor of type #{arg.class}: #{arg}"
        end
      end

      # Only going to support single file for now
      def source_filename
        @source_filename ||= extract.first
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
        @logger.info "Converting #{source_filename} to a dataframe"
        Daru::DataFrame.from_csv source_filename, @csv_options
      end

      def df
        @dataframe ||= to_dataframe
      end
    end
  end
end
