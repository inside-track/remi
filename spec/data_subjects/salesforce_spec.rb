require_relative '../remi_spec'
require 'remi/data_subjects/salesforce.rb'

describe Extractor::Salesforce do
  let(:extractor) { Extractor::Salesforce.new(object: :Contact, credentials: {}, query: '') }
  let(:sf_bulk) { double('sf_bulk') }
  let(:data) do
    {
      'batches' => [
        {
          'id' => ['751160000065e2BAAQ'],
          'state' => [ 'Completed' ]
        }
      ]
    }
  end

  before do
    allow(extractor).to receive(:sf_bulk) { sf_bulk }
    allow(sf_bulk).to receive(:query) { data }
  end

  context '#data' do
    it 'returns extracted data' do
      expect(extractor.extract.data).to eq data
    end
  end


  it 'raises an error if the batch fails' do
    data['batches'].first['state'] = ['Error']
    expect { extractor.extract }.to raise_error Extractor::Salesforce::ExtractError
  end
end


describe Parser::Salesforce do
  let(:parser) { Parser::Salesforce.new }
  let(:sf_extract) { double('sf_extract') }
  let(:data) do
    {
      'batches' => [
        {
          'id' => ['751160000065e2BAAQ'],
          'state' => [ 'Completed' ],
          'response' => [
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "003G000001cKYaUIA4",
                "003G000001cKYaUIA4"
              ],
              "Student_ID__c" => [
                "FJD385628"
              ]
            },
            {
              "xsi:type" => "sObject",
              "type" => [
                "Contact"
              ],
              "Id" => [
                "003G000001cKYbXIA4",
                "003G000001cKYbXIA4"
              ],
              "Student_ID__c" => [
                { 'xsi:nil' => 'true' }
              ]
            }
          ]
        }
      ]
    }
  end

  before do
    allow(sf_extract).to receive(:data) { data }
  end

  it 'converts SalesforceBulkApi response data into a dataframe' do
    expect(parser.parse sf_extract).to be_a Remi::DataFrame::Daru
  end

  it 'converted data into the correct dataframe' do
    expected_df = Daru::DataFrame.new(
      :Id            => ['003G000001cKYaUIA4', '003G000001cKYbXIA4'],
      :Student_ID__c => ['FJD385628', nil]
    )
    expect(parser.parse(sf_extract).to_a).to eq expected_df.to_a
  end
end


describe Encoder::Salesforce do
  let(:encoder) { Encoder::Salesforce.new }
  let(:dataframe) do
    Daru::DataFrame.new(
      :Id            => ['003G000001cKYaUIA4', '003G000001cKYbXIA4'],
      :Student_ID__c => ['FJD385628', nil]
    )
  end

  it 'converts the dataframe into an array of hashes' do
    expected_result = [
      { :Id => '003G000001cKYaUIA4', :Student_ID__c => 'FJD385628' },
      { :Id => '003G000001cKYbXIA4', :Student_ID__c => nil },
    ]
    expect(encoder.encode dataframe).to eq expected_result
  end
end


describe Loader::Salesforce, skip: 'todo' do
end
