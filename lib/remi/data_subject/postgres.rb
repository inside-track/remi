module Remi
  module DataSubject::Postgres
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


  class DataSource::Postgres < DataSource
    include Remi::DataSubject::Postgres


    def initialize(*args, **kargs, &block)
      super
      init_postgres(*args, **kargs, &block)
    end

    # Public: Called to extract data from the source.
    #
    # Returns data in a format that can be used to create a dataframe.
    def extract!
      @logger.info "Executing query #{@query}"
      @extract = connection.exec @query
    end

    # Public: Converts extracted data to a dataframe.
    # Currently only supports Daru DataFrames.
    #
    # Returns a Remi::DataFrame
    def to_dataframe
      # Performance for larger sets could be improved by using bulk query (via COPY)
      @logger.info "Converting query to a dataframe"

      hash_array = {}
      extract.each do |row|
        row.each do |field, value|
          (hash_array[field_symbolizer.call(field)] ||= []) << value
        end
      end

      # After converting to DF, clear the PG results to save memory.
      extract.clear

      Remi::DataFrame.create(@remi_df_type, hash_array, order: hash_array.keys)
    end


    private

    def init_postgres(*args, credentials:, query:, **kargs, &block)
      @credentials = credentials
      @query = query
    end
  end



  # VERY PRELIMINARY IMPLEMENTAtION - ONLY LOADS TO TEMP TABLES
  # IT IS THEN UP TO THE USER TO DO ELT TO LOAD THE FINAL TABLE
  class DataTarget::Postgres < DataTarget
    include Remi::DataSubject::Postgres

    def initialize(*args, **kargs, &block)
      super
      init_postgres(*args, **kargs, &block)
    end

    # Public: Performs the load operation, regardless of whether it has
    # already executed.
    #
    # Returns true if the load operation was successful
    def load!
      @logger.info "Performing postgres load to table #{@table_name}"
      create_target_table
      load_target_table

      true
    end


    private

    def init_postgres(*args, credentials:, table_name:, **kargs, &block)
      @credentials = credentials
      @table_name = table_name
    end

    def fields_with_type_ddl
      @fields.map { |k,v| "#{k} #{v[:type]}" }.join(', ')
    end

    def create_target_table
      create_table_sql = <<-EOT
        CREATE TEMPORARY TABLE #{@table_name} (
          #{fields_with_type_ddl}
        )
      EOT

      @logger.info create_table_sql
      connection.exec create_table_sql
    end

    def load_target_table
      connection.copy_data "COPY #{@table_name} (#{@fields.keys.join(', ')}) FROM STDIN" do
        df.each(:row) do |row|
          row_str = @fields.keys.map do |field|
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

          connection.put_copy_data row_str + "\n"
        end
      end
    end
  end
end
