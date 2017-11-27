module Remi
  # Contains methods shared between Postgres Extractor/Parser/Encoder/Loader
  module DataSubject::Postgres

    # @return [PG::Connection] An authenticated postgres connection
    def connection
      @connection ||= PG.connect(
        host:     @credentials[:host] || 'localhost',
        port:     @credentials[:port] || 5432,
        dbname:   @credentials[:dbname],
        user:     @credentials[:user] || `whoami`.chomp,
        password: @credentials[:password],
        sslmode:  @credentials[:sslmode] || 'allow'
      )
    end
  end

  # Postgres extractor
  #
  # @example
  #  class MyJob < Remi::Job
  #    source :some_table do
  #      extractor Remi::Extractor::Postgres.new(
  #        credentials: {
  #          dbname: 'my_local_db'
  #        },
  #        query: 'SELECT * FROM job_specs'
  #      )
  #      parser Remi::Parser::Postgres.new
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.some_table.df[:id, :name]
  #  # =>#<Daru::DataFrame:70153144824760 @name = 53c8e878-55e7-4859-bc34-ec29309c11fd @size = 3>
  #  #                    id       name
  #  #          0         24 albert
  #  #          1         26 betsy
  #  #          2         25 camu

  class Extractor::Postgres < Extractor
    include DataSubject::Postgres

    # @param credentials [Hash] Used to authenticate with the postgres db
    # @option credentials [String] :host Postgres host (default: localhost)
    # @option credentials [Integer] :port Postgres host (default: 5432)
    # @option credentials [String] :dbname Database name
    # @option credentials [String] :user Postgres login username (default: `whoami`)
    # @option credentials [String] :password Postgres login password
    # @option credentials [String] :sslmode Postgres SSL mode (default: allow)
    # @param query [String] Query to use to extract data
    def initialize(*args, **kargs, &block)
      super
      init_postgres_extractor(*args, **kargs, &block)
    end

    # @return [Object] Data extracted from Postgres system
    attr_reader :data

    # @return [Object] self after querying Postgres data
    def extract
      logger.info "Executing Postgres query #{@query}"
      @data = execute_query
      self
    end

    private

    def execute_query
      connection.exec @query
    end

    def init_postgres_extractor(*args, credentials:, query:, **kargs, &block)
      @credentials = credentials
      @query = query
    end
  end


  # Postgres parser
  # Used to parse results from a postgres extractor (see Extractor::Postgres).
  class Parser::Postgres < Parser

    # @param postgres_extract [Extractor::Postgres] An object containing data extracted from Postgres
    # @return [Remi::DataFrame] The data converted into a dataframe
    def parse(postgres_extract)
      # Performance for larger sets could be improved by using bulk query (via COPY)
      logger.info "Converting Postgres query to a dataframe"

      hash_array = {}
      postgres_extract.data.each do |row|
        row.each do |field, value|
          (hash_array[field_symbolizer.call(field)] ||= []) << value
        end
      end

      # After converting to DF, clear the PG results to save memory.
      postgres_extract.data.clear

      df_fields = fields.keys | hash_array.keys
      Remi::DataFrame.create(:daru, hash_array, order: df_fields)
    end
  end


  # Postgres encoder
  class Encoder::Postgres < Encoder

    # @return [Array<String>] All records of the dataframe encoded as strings to be used by Postgres Bulk updater
    attr_accessor :values

    # Converts the dataframe to an array of hashes, which can be used
    # by the postgres loader.
    #
    # @param dataframe [Remi::DataFrame] The dataframe to be encoded
    # @return [Object] The encoded data to be loaded into the target
    def encode(dataframe)
      @values = encode_data(dataframe)
      self
    end

    # @return [String] Field definitions to be used in the DDL
    def ddl_fields
      fields.map { |k,v| "#{k} #{v[:type]}" }.join(', ')
    end

    private

    def encode_data(dataframe)
      dataframe.map(:row) do |row|
        fields.keys.map do |field|
          field = row[field]
          case
          when field.respond_to?(:strftime)
            field.strftime('%Y-%m-%d %H:%M:%S')
          when field.respond_to?(:map)
            field.to_json.gsub("\t", '\t')
          when field.blank? && !field.nil?
            ''
          when field.nil?
            '\N'
          else
            field.to_s.gsub(/[\t\n\r]/, "\t" => '\t', "\n" => '\n', "\r" => '\r')
          end
        end.join("\t")
      end
    end
  end


  # Postgres Loader
  # VERY PRELIMINARY IMPLEMENTAtION - ONLY LOADS TO TEMP TABLES
  # IT IS THEN UP TO THE USER TO DO ELT TO LOAD THE FINAL TABLE
  class Loader::Postgres < Loader
    include DataSubject::Postgres

    def initialize(*args, **kargs, &block)
      super
      init_postgres_loader(*args, **kargs, &block)
    end

    # @param data [Encoder::Postgres] Data that has been encoded appropriately to be loaded into the target
    # @return [true] On success
    def load(data)
      logger.info "Performing postgres load to table #{@table_name}"
      create_table_sql = "CREATE TEMPORARY TABLE #{@table_name} (#{data.ddl_fields})"
      logger.info create_table_sql
      connection.exec create_table_sql

      connection.copy_data "COPY #{@table_name} (#{data.fields.keys.join(', ')}) FROM STDIN" do
        data.values.each do |row|
          connection.put_copy_data "#{row}\n"
        end
      end

      true
    end


    private

    def init_postgres_loader(*args, credentials:, table_name:, **kargs, &block)
      @credentials = credentials
      @table_name = table_name
    end
  end
end
