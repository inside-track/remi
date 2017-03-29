require 'restforce'
require 'salesforce_bulk_api'
require 'remi/sf_bulk_helper'

module Remi

  # Contains methods shared between Salesforce Extractor/Parser/Encoder/Loader
  module DataSubject::Salesforce

    # @return [Restforce] An authenticated restforce client
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


  # Salesforce extractor
  #
  # @example
  #
  #  class MyJob < Remi::Job
  #    source :contacts do
  #      extractor Remi::Extractor::Salesforce.new(
  #        credentials: { },
  #        object: :Contact,
  #        api: :bulk,
  #        query: 'SELECT Id, Student_ID__c, Name FROM Contact LIMIT 1000'
  #      )
  #      parser Remi::Parser::Salesforce.new
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.contacts.df
  #  # #<Daru::DataFrame:70134211545860 @name = 7cddb460-6bfc-4737-a72c-60ed2c1a97d5 @size = 1>
  #  #                    Id Student_ID       Name
  #  #          0 0031600002   test1111  Run Logan
  class Extractor::Salesforce < Extractor
    include Remi::DataSubject::Salesforce

    class ExtractError < StandardError; end

    # @param credentials [Hash] Used to authenticate with salesforce
    # @option credentials [String] :host Salesforce host (e.g., login.salesforce.com)
    # @option credentials [String] :client_id Salesforce Rest client id
    # @option credentials [String] :client_secret Salesforce Rest client secret
    # @option credentials [String] :instance_url Salesforce instance URL (e.g., https://na1.salesforce.com)
    # @option credentials [String] :username Salesforce username
    # @option credentials [String] :password Salesforce password
    # @option credentials [String] :security_token Salesforce security token
    # @param object [Symbol] Salesforce object to extract
    # @param query [String] The SOQL query to execute to extract data
    # @param api [Symbol] Salesforce API to use (only option supported is `:bulk`)
    def initialize(*args, **kargs, &block)
      super
      init_salesforce_extractor(*args, **kargs, &block)
    end

    attr_reader :data

    # @return [Object] self after querying salesforce data
    def extract
      logger.info "Executing salesforce query #{@query}"
      @data = sf_bulk.query(@sfo, @query, 10000)
      check_for_errors(@data)
      self
    end

    # @return [SalesforceBulkApi::Api] The bulk API salesforce client
    def sf_bulk
      SalesforceBulkApi::Api.new(restforce_client).tap { |o| o.connection.set_status_throttle(5) }
    end

    private

    def init_salesforce_extractor(*args, object:, query:, credentials:, api: :bulk, **kargs, &block)
      @sfo         = object
      @query       = query
      @credentials = credentials
      @api         = api
    end

    def check_for_errors(sf_result)
      sf_result['batches'].each do |batch|
        raise ExtractError, "Error with batch #{batch['id']} - #{batch['state']}: #{batch['stateMessage']}" unless batch['state'].first == 'Completed'
      end
    end
  end

  # Salesforce parser
  class Parser::Salesforce < Parser

    # @param sf_extract [Extractor::Salesforce] An object containing data extracted from salesforce
    # @return [Remi::DataFrame] The data converted into a dataframe
    def parse(sf_extract)
      logger.info 'Parsing salesforce query results'

      hash_array = {}
      sf_extract.data['batches'].each do |batch|
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

      Remi::DataFrame.create(:daru, hash_array, order: hash_array.keys)
    end
  end

  # Salesforce encoder
  class Encoder::Salesforce < Encoder
    # Converts the dataframe to an array of hashes, which can be used
    # by the salesforce bulk api.
    #
    # @param dataframe [Remi::DataFrame] The dataframe to be encoded
    # @return [Object] The encoded data to be loaded into the target
    def encode(dataframe)
      dataframe.to_a[0]
    end
  end

  # Salesforce loader
  #
  # @example
  #  class MyJob < Remi::Job
  #    target :contacts do
  #      encoder Remi::Encoder::Salesforce.new
  #      loader Remi::Loader::Salesforce.new(
  #        credentials: { },
  #        object: :Contact,
  #        api: :bulk,
  #        operation: :update
  #      )
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.contacts.df = Daru::DataFrame.new({ :Id => ['0031600002Pm7'], :Student_ID__c => ['test1111']})
  #  job.contacts.load
  class Loader::Salesforce < Loader
    include Remi::DataSubject::Salesforce

    # @param credentials [Hash] Used to authenticate with salesforce
    # @option credentials [String] :host Salesforce host (e.g., login.salesforce.com)
    # @option credentials [String] :client_id Salesforce Rest client id
    # @option credentials [String] :client_secret Salesforce Rest client secret
    # @option credentials [String] :instance_url Salesforce instance URL (e.g., https://na1.salesforce.com)
    # @option credentials [String] :username Salesforce username
    # @option credentials [String] :password Salesforce password
    # @option credentials [String] :security_token Salesforce security token
    # @param object [Symbol] Salesforce object to extract
    # @param operation [Symbol] Salesforce operation to perform (`:update`, `:create`, `:upsert`, `:delete`)
    # @param batch_size [Integer] Size of batch to use for updates (1-10000)
    # @param external_id [Symbol, String] Field to use as an external id for upsert operations
    # @param api [Symbol] Salesforce API to use (only option supported is `:bulk`)
    def initialize(*args, **kargs, &block)
      super
      init_salesforce_loader(*args, **kargs, &block)
    end

    # @param data [Encoder::Salesforce] Data that has been encoded appropriately to be loaded into the target
    # @return [true] On success
    def load(data)
      logger.info "Performing Salesforce #{@operation} on object #{@sfo}"

      if @operation == :update
        Remi::SfBulkHelper::SfBulkUpdate.update(restforce_client, @sfo, data, batch_size: @batch_size, logger: logger)
      elsif @operation == :create
        Remi::SfBulkHelper::SfBulkCreate.create(restforce_client, @sfo, data, batch_size: @batch_size, max_attempts: 1, logger: logger)
      elsif @operation == :upsert
        Remi::SfBulkHelper::SfBulkUpsert.upsert(restforce_client, @sfo, data, batch_size: @batch_size, external_id: @external_id, logger: logger)
      elsif @operation == :delete
        Remi::SfBulkHelper::SfBulkDelete.delete(restforce_client, @sfo, data, batch_size: @batch_size, logger: logger)
      else
        raise ArgumentError, "Unknown operation: #{@operation}"
      end

      true
    end

    private

    def init_salesforce_loader(*args, object:, operation:, credentials:, batch_size: 5000, external_id: 'Id', api: :bulk, **kargs, &block)
      @sfo         = object
      @operation   = operation
      @batch_size  = batch_size
      @external_id = external_id
      @credentials = credentials
      @api         = api
    end

  end

end
