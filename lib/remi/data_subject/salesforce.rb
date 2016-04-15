require 'restforce'
require 'salesforce_bulk_api'
require 'remi/sf_bulk_helper'

module Remi
  module DataSubject::Salesforce
    def field_symbolizer
      Remi::FieldSymbolizers[:salesforce]
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
  end


  class DataSource::Salesforce < Remi::DataSubject
    include Remi::DataSubject::DataSource
    include Remi::DataSubject::Salesforce

    def initialize(*args, **kargs, &block)
      super
      init_salesforce(*args, **kargs, &block)
    end

    # Public: Called to extract data from the source.
    #
    # Returns data in a format that can be used to create a dataframe.
    def extract!
      @extract = sf_bulk.query(@sfo, @query, 10000)

      check_for_errors(@extract)
      @extract
    end

    def sf_bulk
      @sf_bulk ||= SalesforceBulkApi::Api.new(restforce_client).tap { |o| o.connection.set_status_throttle(5) }
    end

    # Public: Converts extracted data to a dataframe.
    # Currently only supports Daru DataFrames.
    #
    # Returns a Remi::DataFrame
    def to_dataframe
      @logger.info "Converting salesforce query results to a dataframe"

      hash_array = {}
      extract['batches'].each do |batch|
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

      Remi::DataFrame.create(@remi_df_type, hash_array, order: hash_array.keys)
    end


    private

    def init_salesforce(*args, object:, query:, credentials:, api: :bulk, **kargs, &block)
      @sfo = object
      @query = query
      @credentials = credentials
      @api = api
    end

    def check_for_errors(sf_result)
      sf_result['batches'].each do |batch|
        raise "Error with batch #{batch['id']} - #{batch['state']}: #{batch['stateMessage']}" unless batch['state'].first == 'Completed'
      end
    end
  end


  class DataTarget::Salesforce < Remi::DataSubject
    include Remi::DataSubject::DataTarget
    include Remi::DataSubject::Salesforce

    def initialize(*args, **kargs, &block)
      super
      init_salesforce(*args, **kargs, &block)
    end

    # Public: Performs the load operation, regardless of whether it has
    # already executed.
    #
    # Returns true if the load operation was successful
    def load!
      @logger.info "Performing Salesforce #{@operation} on object #{@sfo}"

      if @operation == :update
        Remi::SfBulkHelper::SfBulkUpdate.update(restforce_client, @sfo, df_as_array_of_hashes, logger: @logger)
      elsif @operation == :create
        Remi::SfBulkHelper::SfBulkCreate.create(restforce_client, @sfo, df_as_array_of_hashes, logger: @logger)
      elsif @operation == :upsert
        Remi::SfBulkHelper::SfBulkUpsert.upsert(restforce_client, @sfo, df_as_array_of_hashes, external_id: @external_id, logger: @logger)
      else
        raise ArgumentError, "Unknown operation: #{@operation}"
      end

      true
    end

    private

    def init_salesforce(*args, object:, operation:, credentials:, external_id: 'Id', api: :bulk, **kargs, &block)
      @sfo = object
      @operation = operation
      @external_id = external_id
      @credentials = credentials
      @api = api
    end
  end


end
