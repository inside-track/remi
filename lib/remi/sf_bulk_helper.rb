module Remi
  module SfBulkHelper

    class DupeLookupKeyError < StandardError; end
    class MaxAttemptError < StandardError; end

    # Public: Class used to execute SF Bulk operations.  This class is not meant to be
    # used directly.  It is instead meant to be inherited by classes that perform the
    # specific query, update, create, or upsert operations.
    #
    # Examples
    #
    #   sf_query = SfBulkQuery.query(client, 'Contact', 'SELECT Id, Name FROM Contact')
    #   puts sf_query.result
    #
    #   mydata = [ { 'Id' => '001G000000ncxb8IAA', 'Name' => 'Happy Feet' } ]
    #   sf_update = SfBulkUpdate.update(client, 'Contact', mydata)
    class SfBulkOperation

      # Public: Initializes a SfBulkOperation (does not execute operation).
      #
      # restforce_client - An instance of Restforce that is used to authenticate the connection.
      # object           - The name of the object to operate on (e.g., Contact, Task, etc).
      # data             - For query operations, this is the SOQL query string.  For other
      #                    operations, this is an array of hashes, where the hash keys are column names
      #                    and the values are the data.
      # batch_size       - Batch size to use to download or upload data (default: 10000)
      # max_mattempts    - The maximum number of attempts to upload data (default: 2)
      # logger           - Logger to use (default: Logger.new(STDOUT)
      def initialize(restforce_client, object, data, batch_size: 5000, max_attempts: 2, logger: Logger.new(STDOUT))
        @restforce_client = restforce_client
        @object = object
        @data = data
        @batch_size = batch_size
        @max_attempts = max_attempts
        @attempts = Hash.new(0)
        @logger = logger
      end

      # Public: A symbol representing the operation to be performed (:query, :update, :create, :upsert)
      def operation
        :undefined
      end

      # Public: Returns the instance of SalesforceBulkApi::Api used for bulk operations.
      def sf_bulk
        @sf_bulk ||= SalesforceBulkApi::Api.new(@restforce_client).tap { |o| o.connection.set_status_throttle(5) }
      end

      # Public: Returns the raw result from the SalesforceBulkApi query
      def raw_result
        @raw_result || execute
      end

      # Public: Returns useful metadata about the batch query.
      def info
        execute if @attempts[:total] == 0

        return @info if @info and @attempts[:info] == @attempts[:total]
        @attempts[:info] += 1

        @info = raw_result.reject { |k,v| k == 'batches' }.tap do |h|
          h['query'] = @data if operation == :query
        end
      end

      # Public: Collects the results from all of the batches and aggregates them
      # into an array of hashes.  Each element of the array represents a record in the
      # result and the hash gives the column-value.  Note that if multiple retries are
      # needed, this is just the final result.
      #
      # Returns an array of hashes.
      def result
        execute if @attempts[:total] == 0

        return @result if @result and @attempts[:result] == @attempts[:total]
        @attempts[:result] += 1

        @result = []
        raw_result['batches'].each do |batch|
          next unless batch['response']

          batch['response'].each do |record|
            @result << record.inject({}) { |h, (k,v)| h[k] = v.first unless ['xsi:type','type'].include? k; h }
          end

          # delete raw result at end of processing to free memory
          batch['response'] = nil
        end

        @result
      end

      # Public: Converts the result into a hash that can be used to
      # lookup the row for a given key (e.g., external id field).
      #
      # key        - A string representing the name of the column to be used as the lookup key.
      # duplicates - Indicates whether duplicate keys are allowed.  If they are allowed,
      #              only the first row found will be retained.  If duplicates are not allowed,
      #              an error is raised (default: false).
      #
      # Returns a hash.
      def as_lookup(key:, duplicates: false)
        execute if @attempts[:total] == 0

        @as_lookup ||= {}
        @attempts[:as_lookup] = Hash.new(0) if @attempts[:as_lookup] == 0

        return @as_lookup[key] if @as_lookup[key] and @attempts[:as_lookup][key] == @attempts[:total]
        @attempts[:as_lookup][key] += 1

        @as_lookup[key] = result.inject({}) do |lkp,row|
          raise DupeLookupKeyError, "Duplicate key: #{row[key]} found in result of query: #{@data}" if lkp.has_key?(row[key]) and not duplicates
          lkp[row[key]] = row unless lkp.has_key?(row[key])
          lkp
        end
      end


      # Public: Returns true if any of the records failed to update.
      def failed_records?
        n_failed_records = result.reduce(0) do |count, row|
          count += 1 if row['success'] != 'true'
          count
        end

        n_failed_batches = raw_result['batches'].reduce(0) do |count, batch|
          count += 1 if batch['state'].first != 'Completed'
          count
        end

        n_failed_records > 0 || n_failed_batches > 0
      end


      private

      # Private: Sends the operation to Salesforce using the bulk API.
      def send_bulk_operation
        raise "No SF bulk operation defined for #{operation}"
      end

      # Private: Executes the operation and retries if needed.
      def execute
        @attempts[:total] += 1
        @logger.info "Executing Salesforce Bulk operation: #{operation}"

        @raw_result = send_bulk_operation
        @logger.info "Bulk operation response: "
        JSON.pretty_generate(info).split("\n").each { |l| @logger.info l }

        retry_failed if failed_records?

        @logger.info JSON.pretty_generate(info)
        @raw_result
      end

      # Private: Drops any data that has already been loaded to salesforce.
      # Note that this doesn't work for created data since the initial data
      # wont have a salesforce id.  Sometimes batches can fail completely
      # and won't give anything in the result set.  Therefore, the only way
      # to be able to drop data that's already been created would be to
      # know how the data was split into batches and the gem we use does not
      # make this simple.  So for now, we live with the defect.
      def drop_successfully_updated_data
        lkp_result_by_id = as_lookup(key: 'id', duplicates: true)
        @data.reject! do |row|
          sf_bulk_result = lkp_result_by_id[row['Id'] || row[:Id]]
          sf_bulk_result && (sf_bulk_result['success'] == 'true')
        end

        nil
      end


      # Private: Selects data needed to be retried and re-executes the operation.
      def retry_failed
        raise MaxAttemptError if @attempts[:total] >= @max_attempts
        @logger.warn "Retrying #{operation} - #{@attempts[:total]} of #{@max_attempts}"

        drop_successfully_updated_data

        execute
      end
    end


    # Public: Class used to execute SF Bulk Update operations (see SfBulkOperation class for
    # more details).
    class SfBulkUpdate < SfBulkOperation
      def self.update(*args,**kargs)
        SfBulkUpdate.new(*args,**kargs).tap { |sf| sf.send(:execute) }
      end

      def operation
        :update
      end

      private

      def send_bulk_operation
        sf_bulk.send(operation, @object, @data, true, false, [], @batch_size)
      end
    end

    # Public: Class used to execute SF Bulk Create operations (see SfBulkOperation class for
    # more details).
    class SfBulkCreate < SfBulkOperation
      def self.create(*args,**kargs)
        SfBulkCreate.new(*args,**kargs).tap { |sf| sf.send(:execute) }
      end

      def operation
        :create
      end

      private

      def send_bulk_operation
        sf_bulk.send(operation, @object, @data, true, false, @batch_size)
      end
    end

    # Public: Class used to execute SF Bulk Upsert operations (see SfBulkOperation class for
    # more details).
    class SfBulkUpsert < SfBulkOperation
      def self.upsert(*args,**kargs)
        SfBulkUpsert.new(*args,**kargs).tap { |sf| sf.send(:execute) }
      end

      def operation
        :upsert
      end

      private

      def send_bulk_operation
        # Upsert does not support external id right now
        sf_bulk.send(operation, @object, @data, 'Id', true, false, [], @batch_size)
      end
    end

    # Public: Class used to execute SF Bulk Query operations (see SfBulkOperation class for
    # more details).
    class SfBulkQuery < SfBulkOperation
      def self.query(*args,**kargs)
        SfBulkQuery.new(*args,**kargs).tap { |sf| sf.send(:execute) }
      end

      def operation
        :query
      end

      def failed_records?
        false
      end

      private

      def send_bulk_operation
        sf_bulk.send(operation, @object, @data, @batch_size)
      end
    end
  end
end
