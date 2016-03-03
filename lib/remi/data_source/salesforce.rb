module Remi
  module DataSource
    class Salesforce
      include DataSource

      def initialize(fields: {}, object:, query:, credentials:, api: :bulk, logger: Remi::Settings.logger)
        @fields = fields
        @sfo = object
        @query = query
        @credentials = credentials
        @api = api
        @logger = logger
      end

      attr_accessor :fields
      attr_accessor :raw_result

      def field_symbolizer
        Remi::FieldSymbolizers[:salesforce]
      end

      def extract
        @raw_result = sf_bulk.query(@sfo, @query, 10000)

        check_for_errors(@raw_result)
        @raw_result
      end

      def check_for_errors(sf_result)
        sf_result['batches'].each do |batch|
          raise "Error with batch #{batch['id']} - #{batch['state']}: #{batch['stateMessage']}" unless batch['state'].first == 'Completed'
        end
      end

      def raw_result
        @raw_result ||= extract
      end



      def restforce_client
        @restforce_client ||= begin
          client = Restforce.new(@credentials)

          #run a dummy query to initiate a connection. Workaround for Bulk API problem
          # https://github.com/yatish27/salesforce_bulk_api/issues/33
          client.query('SELECT Id FROM Contact LIMIT 1')
          client
        end
      end

      def sf_bulk
        @sf_bulk ||= SalesforceBulkApi::Api.new(restforce_client).tap { |o| o.connection.set_status_throttle(5) }
      end

      def to_dataframe
        @logger.info "Converting salesforce query results to a dataframe"

        hash_array = {}
        raw_result['batches'].each do |batch|
          next unless batch['response']

          batch['response'].each do |record|
            record.each do |field, value|
              next if ['xsi:type','type'].include? field
              (hash_array[field.to_sym] ||= []) << case value.first
                when Hash
                  value.first["xsi:nil"] == "true" ? nil : value.first
                else
                  value.first
                end
            end
          end

          # delete raw result at end of processing to free memory
          batch['response'] = nil
        end

        Daru::DataFrame.new hash_array, order: hash_array.keys
      end

      def df
        @dataframe ||= to_dataframe
      end
    end
  end
end
