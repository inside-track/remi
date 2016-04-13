module Remi
  module DataTarget
    class Salesforce
      include DataTarget

      def initialize(object:, operation:, credentials:, external_id: 'Id', api: :bulk, logger: Remi::Settings.logger)
        @sfo = object
        @operation = operation
        @external_id = external_id
        @credentials = credentials
        @api = api
        @logger = logger
      end

      def field_symbolizer
        Remi::FieldSymbolizers[:salesforce]
      end

      def load
        return true if @loaded || df.size == 0

        @logger.info "Performing Salesforce #{@operation} on object #{@sfo}"

        if @operation == :update
          Remi::SfBulkHelper::SfBulkUpdate.update(restforce_client, @sfo, df_as_array_of_hashes, logger: @logger)
        elsif @operation == :create
          Remi::SfBulkHelper::SfBulkCreate.create(restforce_client, @sfo, df_as_array_of_hashes, logger: @logger)
        elsif @operation == :upsert
          Remi::SfBulkHelper::SfBulkUpsert.upsert(restforce_client, @sfo, df_as_array_of_hashes, external_id: @external_id, logger: @logger)
        else
          raise "Unknown operation: #{@operation}"
        end

        @loaded = true
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

      def df_as_array_of_hashes
        df.to_a[0]
      end

    end
  end
end
