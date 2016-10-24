require 'remi_spec'
require 'remi/data_subjects/gsheet'

describe Extractor::Gsheet do

  let(:remote_path) { '' }
  let(:credentials) {
    {
      :client_id        => 'some_client_id',
      :access_token     => 'some_access_token',
      :refresh_token    => 'some_refresh_token',
      :client_secret    => 'some_client_secret',
      :application_name => 'some_application_name',
      :project_id       => 'some_project_id',
      :expiration_time  => '123456789'
    }
  }


  let(:params) {
    {
      credentials: credentials,
      folder_id:   'some_google_folder_id',
      remote_path: remote_path
    }
  }

  let(:gsheet_file) {
    Extractor::Gsheet.new(params)
  }

  let(:response) { double('response') }
  let(:remote_filenames) {["test_file_1","test_file_2"]}
  let(:remote_files) do
    [{name: "test_file_1", create_time:Date.current, id: "1234"},
     {name: "test_file_2", create_time:Date.current, id: "5678"}]

  end

  context '.new' do
    it 'creates an instance with valid parameters' do
      gsheet_file
    end

    it 'requires a client_id' do
      credentials.delete(:client_id)
      expect { gsheet_file }.to raise_error KeyError
    end

    it 'requires an access_token' do
      credentials.delete(:access_token)
      expect { gsheet_file }.to raise_error KeyError
    end

    it 'requires a client_secret' do
      credentials.delete(:client_secret)
      expect { gsheet_file }.to raise_error KeyError
    end

    it 'requires a refresh_token' do
      credentials.delete(:refresh_token)
      expect { gsheet_file }.to raise_error KeyError
    end

    it 'requires a folder id' do
      params.delete(:credentials)
      expect { gsheet_file }.to raise_error ArgumentError
    end

    it 'requires an application name' do
      credentials.delete(:application_name)
      expect { gsheet_file }.to raise_error KeyError
    end

    it 'requires a project id' do
      credentials.delete(:project_id)
      expect { gsheet_file }.to raise_error KeyError
    end

  end

  context '#all_entires' do
    it 'returns all entries' do

      allow(response).to receive(:files) { remote_files }
      allow(gsheet_file).to receive(:service_list_files) { response }

      expect(gsheet_file.all_entries.map(&:name)).to eq remote_filenames

    end
  end

  context '#extract' do
    it 'downloads files from google' do

      allow(response).to receive(:files) { remote_files }
      allow(gsheet_file).to receive(:service_list_files) { response }
      expect(gsheet_file).to receive(:get_spreadsheet_vals).exactly(remote_filenames.size).times
      gsheet_file.extract

    end

  end
end

describe Parser::Gsheet do

  let(:parser) { Parser::Gsheet.new }
  let(:gs_extract) { double('gs_extract') }
  let(:example_data) do
    [{"headers" => ["header_1", "header_2", "header_3"],
      "row 1"   => ["value 1", "value 2", "value 3"]
    }]
  end

  before do
    allow(gs_extract).to receive(:data) { example_data }
  end

  it 'converts Google Sheets response data into a dataframe' do
    expect(parser.parse gs_extract).to be_a Remi::DataFrame::Daru
  end

  it 'converted data into the correct dataframe' do
    expected_df = Daru::DataFrame.new(
      :header_1 => ['value 1'],
      :header_2 => ['value 2'],
      :header_3 => ['value 3'],
    )
    expect(parser.parse(gs_extract).to_a).to eq expected_df.to_a
  end

end
