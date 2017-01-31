require 'soapforce'

module Remi
  module DataSubject::SalesforceSoap
    def soapforce_client
      @soapforce_client ||= begin
        client = Soapforce::Client.new(host: @credentials[:host], logger: logger)
        client.authenticate(
          username: @credentials[:username],
          password: "#{@credentials[:password]}#{@credentials[:security_token]}"
        )
        client
      end
    end
  end

  # Salesforce SOAP encoder
  class Encoder::SalesforceSoap < Encoder
    # Converts the dataframe to an array of hashes, which can be used
    # by the salesforce soap api.
    #
    # @param dataframe [Remi::DataFrame] The dataframe to be encoded
    # @return [Object] The encoded data to be loaded into the target
    def encode(dataframe)
      dataframe.to_a[0]
    end
  end

  # Salesforce SOAP loader
  # The Salesforce SOAP loader can be used to merge salesforce objects (for those
  # objects that support the merge operation).  To do so, each row of the dataframe must
  # contain a field called `:Id` that references the master record that survives the
  # merge operation.  It must also contain a `:Merge_Id` field that specifies the
  # salesforce Id of the record that is to be merged into the master.  Other fields
  # may also be specified that will be used to update the master record.
  #
  # @example
  #  class MyJob < Remi::Job
  #    target :merge_contacts do
  #      encoder Remi::Encoder::SalesforceSoap.new
  #      loader Remi::Loader::SalesforceSoap.new(
  #        credentials: { },
  #        object: :Contact,
  #        operation: :merge,
  #        merge_id_field: :Merge_Id
  #      )
  #    end
  #  end
  #
  #  job = MyJob.new
  #  job.merge_contacts.df = Remi::DataFrame::Daru.new({ Id: ['003g000001IX4HcAAL'], Note__c: ['Cheeseburger in Paradise'], Merge_Id: ['003g000001LE7dXAAT']})
  #  job.merge_contacts.load
  #
  class Loader::SalesforceSoap < Loader
    include Remi::DataSubject::SalesforceSoap

    # @param credentials [Hash] Used to authenticate with salesforce
    # @option credentials [String] :host Salesforce host (e.g., login.salesforce.com)
    # @option credentials [String] :username Salesforce username
    # @option credentials [String] :password Salesforce password
    # @option credentials [String] :security_token Salesforce security token
    # @param object [Symbol] Salesforce object to extract
    # @param operation [Symbol] Salesforce operation to perform (`:merge`) <- Merge is the only operation currently supported
    # @param merge_id_field [Symbol] For merge operations, this is the name of the field containing the id of the record to be merged (default: :Merge_Id)
    def initialize(*args, **kargs, &block)
      super
      init_salesforce_loader(*args, **kargs, &block)
    end

    # @param data [Encoder::Salesforce] Data that has been encoded appropriately to be loaded into the target
    # @return [true] On success
    def load(data)
      logger.info "Performing Salesforce Soap #{@operation} on object #{@sfo}"
      if @operation == :merge
        # The Soapforce gem only supports one slow-ass merge at a time :(
        data.each do |row|
          unless row.include?(@merge_id_field)
            raise KeyError, "Merge id field not found: #{@merge_id_field}"
          end

          merge_id = Array(row.delete(@merge_id_field))
          merge_row = row.select { |_, v| !v.blank? }
          soapforce_client.merge!(@sfo, merge_row, merge_id)
        end
      else
        raise ArgumentError, "Unknown soap operation: #{@operation}"
      end
    end

    private

    def init_salesforce_loader(*args, object:, credentials:, operation:, merge_id_field: :Merge_Id, **kargs, &block)
      @sfo            = object
      @credentials    = credentials
      @operation      = operation
      @merge_id_field = merge_id_field
    end
  end
end
