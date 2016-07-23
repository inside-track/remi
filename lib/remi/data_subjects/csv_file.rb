module Remi

  # @api private
  #
  # Contains methods shared between CsvFile Parser/Encoder
  module DataSubject::CsvFile
    def self.included(base)
      base.extend(CsvFileClassMethods)
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

  # @api public
  #
  # CsvFile parser
  #
  # @example
  #
  #  class MyJob < Remi::Job
  #    source :some_file do
  #      extractor Remi::Extractor::LocalFile.new(
  #        remote_path: 'some_file.csv'
  #      )
  #      parser Remi::Parser::CsvFile.new(
  #        csv_options: {
  #          headers: true,
  #          col_sep: '|'
  #        }
  #      )
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.some_file.df
  #  # =>#<Daru::DataFrame:70153153438500 @name = 4c59cfdd-7de7-4264-8666-83153f46a9e4 @size = 3>
  #  #                    id       name
  #  #          0          1     Albert
  #  #          1          2      Betsy
  #  #          2          3       Camu
  class Parser::CsvFile < Parser
    include Remi::DataSubject::CsvFile

    # @param csv_options [Hash] Standard Ruby CSV parsing options.
    # @param filename_field [Symbol] Name of the field to be used to write
    #  the filename of the CSV being parsed (default: nil, meaning no field will be used)
    # @param preprocessor [Proc] A proc used to pre-process lines of the CSV file before being parsed
    def initialize(*args, **kargs, &block)
      super
      init_csv_file(*args, **kargs, &block)
    end

    # @return [Hash] Csv options hash
    attr_reader :csv_options

    # Converts a list of filenames into a dataframe after parsing them
    # according ot the csv options that were set
    # @param data [Object] Extracted data that needs to be parsed
    # @return [Remi::DataFrame] The data converted into a dataframe
    def parse(data)
      # Assumes that each file has exactly the same structure
      result_df = nil
      Array(data).each_with_index do |filename, idx|
        filename = filename.to_s

        logger.info "Converting #{filename} to a dataframe"
        processed_filename = preprocess(filename)
        csv_df = Daru::DataFrame.from_csv processed_filename, @csv_options

        csv_df[@filename_field] = Daru::Vector.new([filename] * csv_df.size, index: csv_df.index) if @filename_field
        if idx == 0
          result_df = csv_df
        else
          result_df = result_df.concat csv_df
        end
      end

      Remi::DataFrame.create(:daru, result_df)
    end


    private

    def preprocess(filename)
      return filename unless @preprocessor
      logger.info "Preprocessing #{filename}"
      tmp_filename = File.join(Remi::Settings.work_dir, "#{Pathname.new(filename).basename}-#{SecureRandom.uuid}")

      dirname = Pathname.new(tmp_filename).dirname
      FileUtils.mkdir_p(dirname) unless File.directory? dirname

      File.open(tmp_filename, 'w') do |outfile|
        File.foreach(filename) do |in_line|
          outfile.write @preprocessor.call(in_line)
        end
      end

      tmp_filename
    end

    def init_csv_file(*args, csv_options: {}, filename_field: nil, preprocessor: nil, **kargs, &block)
      @csv_options = self.class.default_csv_options.merge(csv_options)
      @filename_field = filename_field
      @preprocessor = preprocessor
    end
  end




  # CsvFile Encoder
  #
  # @example
  #  class MyJob < Remi::Job
  #    target :my_target do
  #      encoder Remi::Encoder::CsvFile.new(
  #        csv_options: { col_sep: '|' }
  #      )
  #      loader Remi::Loader::LocalFile.new(
  #        path: 'test.csv'
  #      )
  #    end
  #  end
  #
  #  my_df = Daru::DataFrame.new({ a: 1.upto(5).to_a, b: 6.upto(10) })
  #  job = MyJob.new
  #  job.my_target.df = my_df
  #  job.my_target.load
  class Encoder::CsvFile < Encoder
    include Remi::DataSubject::CsvFile

    # @param work_path [String,Pathname] Path to a directory used to temporarily store CSV files (default: Settings.work_dir)
    # @param csv_options [Hash] Standard Ruby CSV parser options.
    def initialize(*args, **kargs, &block)
      super
      init_csv_file_encoder(*args, **kargs, &block)
    end

    default_csv_options[:row_sep] = "\n"

    # Converts the dataframe to a CSV file stored in the local work directory.
    #
    # @param dataframe [Remi::DataFrame] The dataframe to be encoded
    # @return [Object] The path to the file
    def encode(dataframe)
      logger.info "Writing CSV file to temporary location #{@working_file}"
      dataframe.write_csv @working_file, @csv_options
      @working_file
    end

    private
    def init_csv_file_encoder(*args, work_path: Settings.work_dir, csv_options: {}, **kargs, &block)
      @working_file = File.join(work_path, SecureRandom.uuid)
      @csv_options = self.class.default_csv_options.merge(csv_options)
    end
  end
end
