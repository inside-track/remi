module Remi
  module DataTarget
    class CsvFile
      include DataTarget

      def self.default_csv_options
        CSV::DEFAULT_OPTIONS.merge({
          headers: true,
          header_converters: Remi::FieldSymbolizers[:standard],
          col_sep: ',',
          encoding: 'UTF-8',
          quote_char: '"',
          row_sep: "\n"
        })
      end

      def initialize(path:, csv_options: {}, logger: Remi::Settings.logger)
        @path = path
        @csv_options = self.class.default_csv_options.merge(csv_options)
        @logger = logger
      end

      attr_reader   :path
      attr_reader   :csv_options

      def field_symbolizer
        self.class.default_csv_options[:header_converters]
      end

      def load
        return true if @loaded || df.size == 0

        @logger.info "Writing CSV file #{@path}"

        df.write_csv @path, @csv_options

        @loaded = true
      end

    end
  end
end
