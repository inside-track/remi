require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'googleauth/user_refresh'

module Remi

  # Contains methods shared between Salesforce Extractor/Parser/Encoder/Loader
  class Extractor::Gsheet < Extractor::FileSystem

    def initialize(*args, **kargs, &block)
      super
      init_gsheet_extractor(*args, **kargs)
    end

    attr_reader :data
    attr_reader :client_id
    attr_reader :client_secret
    attr_reader :access_token
    attr_reader :ref_token
    attr_reader :scope
    attr_reader :expire_time

    def authorize
      credentials = Google::Auth::UserRefreshCredentials.new(
        client_id:     @client_id,
        client_secret: @client_secret,
        scope:         @scope,
        access_token:  @access_token,
        refresh_token: @refresh_token,
        expires_at:    @expiration_time / 1000
      )
    end


    def get_file_list(folder_id)
      service                                 = Google::Apis::DriveV3::DriveService.new
      service.client_options.application_name = @application_name
      service.authorization                   = authorize()
      response                                = service_list_files(service, folder_id)
      response.files
    end

    def service_list_files(service, folder_id)
      service.list_files(q: "'#{folder_id}' in parents", page_size: 10, order_by: 'createdTime desc', fields: 'nextPageToken, files(id, name, createdTime, mimeType)')
    end

    def get_spreadsheet_vals(service, spreadsheet_id)
      service.get_spreadsheet_values(spreadsheet_id, 'Sheet1')
    end

    def extract
      service                                 = Google::Apis::SheetsV4::SheetsService.new
      service.client_options.application_name = @application_name
      service.authorization                   = authorize()
      @data                                   = []

      entries.each do |file|
        response = get_spreadsheet_vals(service, file.raw)
        data.push(response)
      end

      self
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries
      @all_entries ||= all_entries!
    end

    # @return [Array<Extractor::FileSystemEntry>] (Memoized) list of objects in the bucket/prefix
    def all_entries!
      gsheet_entries = get_file_list(@default_folder_id)
      gsheet_entries.map do |entry|
        entry = entry.to_h
        FileSystemEntry.new(
          pathname:       File.join(@default_folder_id, entry[:name]),
          create_time:    entry[:created_time],
          modified_time:  entry[:created_time],
          raw:            entry[:id]
        )
      end
    end

    private

    def init_gsheet_extractor(*args, credentials:, folder_id:, **kargs)
      @default_folder_id   = folder_id
      @oob_uri             = 'urn:ietf:wg:oauth:2.0:oob'
      @application_name    = credentials.fetch(:application_name)

      @client_secrets_path = File.join(
        Dir.home,
        '.credentials/client_secret.json'
      )
      @credentials_path = File.join(
        Dir.home,
        '.credentials/sheets.googleapis.com-ruby-remi.yaml'
      )
      @client_id       = credentials.fetch(:client_id)
      @access_token    = credentials.fetch(:access_token)
      @refresh_token   = credentials.fetch(:refresh_token)
      @client_secret   = credentials.fetch(:client_secret)
      @project_id      = credentials.fetch(:project_id)
      @scope           = ["https://www.googleapis.com/auth/drive","https://www.googleapis.com/auth/spreadsheets"]
      @expiration_time = Integer(credentials.fetch(:expiration_time))
    end
  end

  class Parser::Gsheet < Parser

    def parse(gs_extract)
      google_vals = gs_extract.data
      return_hash = nil
      google_vals.each do |google_val|

        if return_hash.nil?
          return_hash = Hash.new
          google_val.values[0].each do |header|
            return_hash[field_symbolizer.call(header)] = []
          end
        end

        keys_temp = return_hash.keys

        google_val.values[1..-1].each do |rows|
          col_num = 0

          rows.each do |value|
            return_hash[keys_temp[col_num]] << value
            col_num +=1
          end
        end
      end
      Remi::DataFrame.create(:daru, return_hash, order: return_hash.keys)
    end
  end

end
