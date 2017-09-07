require 'google/apis/sheets_v4'
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'googleauth/user_refresh'

module Remi

  # Contains methods shared between Salesforce Extractor/Parser/Encoder/Loader
  class Extractor::Gsheet < Extractor::FileSystem
    # @param credentials [Hash] Used to authenticate with the google sheets server
    # @option credentials [String] :client_id hash string given by google to authenticate user
    # @option credentials [String] :client_secret hast string given as unique id
    # @option credentials [String] :access_token token response when authentication is complete.
    # @option credentials [String] :ref_token token used when re-authenticating with server
    # @option credentials [String] :scope gsheet folders user is allowed to access
    # @option credentials [DateTime] :expire_time time at which token expires (set to end of time)
    def initialize(*args, **kargs, &block)
      super
      init_gsheet_extractor(*args, **kargs)
    end
    # @return [Object] Data extracted from Gsheets
    attr_reader :data

    attr_reader :client_id
    attr_reader :client_secret
    attr_reader :access_token
    attr_reader :ref_token
    attr_reader :scope
    attr_reader :expire_time

    # @return [Google::UserRefreshCredentials] a credential object for google auth
    def authorize
      credentials = Google::Auth::UserRefreshCredentials.new(
        client_id:     @client_id,
        client_secret: @client_secret,
        scope:         @scope,
        access_token:  @access_token,
        refresh_token: @refresh_token,
        expires_at:    @expiration_time / 1000
      )
      credentials
    end
    # @param folder_id [Ruby:String] id given to a folder by google
    # @return [Google::DriveService] A list of files in a given folder
    def get_file_list(folder_id)
      service                                 = Google::Apis::DriveV3::DriveService.new
      service.client_options.application_name = @application_name
      service.authorization                   = authorize()
      response                                = service_list_files(service, folder_id)
      response.files
    end
    # @param service [Google:Object] a reference to the current gsheets object
    # @param folder_id [Ruby:String] id given to a folder by google
    # @return [Google::FileList::Array] A list of files in a given folder filtered by the query q
    def service_list_files(service, folder_id)
      begin
        service.list_files(q: "'#{folder_id}' in parents", page_size: 10, order_by: 'createdTime desc', fields: 'nextPageToken, files(id, name, createdTime, mimeType)')
      rescue Google::Apis::ServerError => err
        logger.error err
        logger.error err.body
        raise err
      end
    end
    # @param service [Google:Object] a reference to the current gsheets object
    # @param spreadsheet_id [Ruby:String] id of the selected google sheet to pull
    # @param sheet_name [Ruby:String] The name of a sheet in a google doc. Defaulted to the original name 'Sheet1'
    # @return [Google::FileList::Array] A list of files in a given folder filtered by the query q
    def get_spreadsheet_vals(service, spreadsheet_id, sheet_name = 'Sheet1')
      service.get_spreadsheet_values(spreadsheet_id, sheet_name)
    end

    def extract
      service                                 = Google::Apis::SheetsV4::SheetsService.new
      service.client_options.application_name = @application_name
      service.authorization                   = authorize()
      @data                                   = []

      entries.each do |file|
        logger.info "Extracting Google Sheet data from #{file.pathname}, with sheet name : #{@sheet_name}"
        begin
          response = get_spreadsheet_vals(service, file.raw, @sheet_name)
        rescue Google::Apis::ServerError => err
          logger.error err
          logger.error err.body
          raise err
        end
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

    def init_gsheet_extractor(*args, credentials:, folder_id:, sheet_name: 'Sheet1', **kargs)
      @default_folder_id   = folder_id
      @sheet_name          = sheet_name
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
  # Google Sheets extractor
    #
    # @example
    #  class MyJob < Remi::Job
    #    source :some_table do
    #      extractor Remi::Extractor::Gsheet.new(
    #        credentials: GsheetCreds,
    #        folder_id: 'SomeId1234',
    #        pattern: /^SomeFileNmae/,
    #        sheet_name: 'SomeSheetName',
    #        remote_path: '/Path/To/File',
    #        most_recent_by: :create_time
    #      )
    #      parser Remi::Parser::Gsheet.new
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
  class Parser::Gsheet < Parser

    def parse(gs_extract)
      return_hash = nil
      gs_extract.data.each do |gs_data|

        if return_hash.nil?
          return_hash = Hash.new
          gs_data.values[0].each do |header|
            return_hash[field_symbolizer.call(header)] = []
          end
        end

        headers = return_hash.keys
        header_idx = headers.each_with_index.to_h

        gs_data.values[1..-1].each do |row|
          headers.each do |header|
            idx = header_idx[header]
            return_hash[header] << (idx < row.size ? row[idx] : nil)
          end
        end
      end
      Remi::DataFrame.create(:daru, return_hash, order: return_hash.keys)
    end
  end

end
