module Remi
  module DataSource
    class Postgres
      include DataSource

      def initialize(fields: {}, credentials:, query:, logger: Remi::Settings.logger)
        @fields = fields
        @credentials = credentials
        @query = query
        @logger = logger
      end

      attr_accessor :fields

      def extract
        @logger.info "Executing query #{@query}"
        @raw_result = connection.exec @query
      end

      def raw_result
        @raw_result ||= extract
      end

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


      def to_dataframe
        # Performance for larger sets could be improved by using bulk query (via COPY)
        @logger.info "Converting query to a dataframe"

        hash_array = {}
        raw_result.each do |row|
          row.each do |field, value|
            (hash_array[field_symbolizer.call(field)] ||= []) << value
          end
        end

        # After converting to DF, clear the PG results to save memory.
        raw_result.clear

        Daru::DataFrame.new hash_array, order: hash_array.keys
      end

      def df
        @dataframe ||= to_dataframe
      end
    end
  end
end
