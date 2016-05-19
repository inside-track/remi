module Remi
  module DataSubject::CsvFile
    def self.included(base)
      base.extend(CsvFileClassMethods)
    end

    def field_symbolizer
      self.class.default_csv_options[:header_converters]
    end

    module CsvFileClassMethods
      def default_csv_options
        @default_csv_options ||= CSV::DEFAULT_OPTIONS.merge({
          headers: true,
          header_converters: Remi::FieldSymbolizers[:standard],
          converters: [],
          col_sep: ',',
          encoding: 'UTF-8',
          quote_char: '"'
        })
      end
    end
  end





  class DataSource::CsvFile < Remi::DataSubject
    include Remi::DataSubject::DataSource
    include Remi::DataSubject::CsvFile

    def initialize(*args, **kargs, &block)
      super
      init_csv_file(*args, **kargs, &block)
    end

    attr_reader   :extractor
    attr_reader   :csv_options

    # Public: Called to extract data from the source.
    #
    # Returns data in a format that can be used to create a dataframe.
    def extract!
      @extract = Array(@extractor.extract)
    end

    # Public: Converts extracted data to a dataframe.
    # Currently only supports Daru DataFrames.
    #
    # Returns a Remi::DataFrame
    def to_dataframe
      # Assumes that each file has exactly the same structure
      result_df = nil
      extract.each_with_index do |filename, idx|
        @logger.info "Converting #{filename} to a dataframe"
        csv_df = Daru::DataFrame.from_csv filename, @csv_options

        csv_df[@filename_field] = Daru::Vector.new([filename] * csv_df.size, index: csv_df.index) if @filename_field
        if idx == 0
          result_df = csv_df
        else
          result_df = result_df.concat csv_df
        end
      end

      Remi::DataFrame.create(:daru, result_df)
    end



    def extractor=(arg)
      case arg
      when Extractor::SftpFile, Extractor::LocalFile, Extractor::S3File
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
      raise "Multiple source files detected" if extract.size > 1
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


    private

    def init_csv_file(*args, extractor:, csv_options: {}, filename_field: nil, **kargs, &block)
      self.extractor = extractor
      @csv_options = self.class.default_csv_options.merge(csv_options)
      @filename_field = filename_field
    end
  end





  class DataTarget::CsvFile < Remi::DataSubject
    include ::Remi::DataSubject::DataTarget
    include ::Remi::DataSubject::CsvFile

    default_csv_options[:row_sep] = "\n"

    def initialize(*args, **kargs, &block)
      super
      init_csv_file(*args, **kargs, &block)
    end

    attr_reader   :csv_options

    # Public: Performs the load operation, regardless of whether it has
    # already executed.
    #
    # Returns true if the load operation was successful
    def load!
      @logger.info "Writing CSV file #{@path}"
      df.write_csv @path, @csv_options
      true
    end


    private

    def init_csv_file(*args, path:, csv_options: {}, **kargs, &block)
      @path = path
      @csv_options = self.class.default_csv_options.merge(csv_options)
    end
  end
end
