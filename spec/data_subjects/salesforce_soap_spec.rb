require_relative '../remi_spec'
require 'remi/data_subjects/salesforce_soap.rb'



describe Encoder::SalesforceSoap do
  let(:encoder) { Encoder::SalesforceSoap.new }
  let(:dataframe) do
    Daru::DataFrame.new(
      :Id            => ['003G000001cKYaUIA4', '003G000001cKYbXIA4'],
      :Student_ID__c => ['FJD385628', nil],
      :Merge_Id__c   => ['003g000001LE7dXAAT','003g000001IX4HcAAL']
    )
  end

  it 'converts the dataframe into an array of hashes' do
    expected_result = [
      { :Id => '003G000001cKYaUIA4', :Student_ID__c => 'FJD385628', :Merge_Id__c => '003g000001LE7dXAAT' },
      { :Id => '003G000001cKYbXIA4', :Student_ID__c => nil,         :Merge_Id__c => '003g000001IX4HcAAL' },
    ]
    expect(encoder.encode dataframe).to eq expected_result
  end
end


describe Loader::SalesforceSoap do
  let(:loader) { Loader::SalesforceSoap.new(object: :Contact, credentials: {}, operation: :merge) }
  let(:soapforce_client) { double('soapforce_client') }

  before do
    allow(loader).to receive(:soapforce_client) { soapforce_client }
  end

  it 'raises an error if an unknown operation is requested' do
    data = [
      { Id: '1234', Custom__c: 'something', Merge_Id: '5678' }
    ]

    loader = Loader::SalesforceSoap.new(object: :Contact, credentials: {}, operation: :not_defined)
    expect { loader.load(data) }.to raise_error ArgumentError
  end

  it 'submits the right merge command' do
    data = [
      { Id: '1234', Custom__c: 'something', Merge_Id: '5678' }
    ]

    expect(soapforce_client).to receive(:merge!) do
      [
        :Contact,
        {
          Id: '1234',
          Custom__c: 'something'
        },
        ['5678']
      ]
    end

    loader.load(data)
  end

  it 'submits a merge command for each row of data' do
    data = [
      { Id: '1', Custom__c: 'something', Merge_Id: '10' },
      { Id: '2', Custom__c: 'something', Merge_Id: '20' }
    ]

    expect(soapforce_client).to receive(:merge!).twice
    loader.load(data)
  end

  it 'excludes blank data fields from the merge command' do
    data = [
      { Id: '1234', Custom__c: '', Merge_Id: '5678' }
    ]

    expect(soapforce_client).to receive(:merge!) do
      [
        :Contact,
        {
          Id: '1234'
        },
        ['5678']
      ]
    end

    loader.load(data)
  end

  it 'raises an error if the merge id field is not found' do
    data = [
      { Id: '1234', Custom__c: 'something', Alt_Merge_Id: '5678' }
    ]

    expect { loader.load(data) }.to raise_error KeyError
  end
end
