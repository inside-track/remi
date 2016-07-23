require_relative 'remi_spec'
require 'remi/data_subjects/salesforce'
require_relative 'fixtures/sf_bulk_helper_stubs'

describe Remi::SfBulkHelper do

  describe SfBulkHelper::SfBulkQuery do
    before do
      @sf_query = SfBulkHelper::SfBulkQuery.new({}, 'Contact', SfBulkHelperStubs.contact_query)
      allow(@sf_query).to receive(:send_bulk_operation) { SfBulkHelperStubs.contact_query_raw_result }
    end


    describe 'info' do
      it 'contains the bulk job id' do
        expect(@sf_query.info['id']).to eq SfBulkHelperStubs.contact_query_raw_result['id']
      end

      it 'contains the query submitted' do
        expect(@sf_query.info['query']).to eq SfBulkHelperStubs.contact_query
      end
    end

    describe 'collected result' do
      it 'returns the number of records specified in info' do
        expect(@sf_query.result.size).to eq @sf_query.info['numberRecordsProcessed'].first.to_i
      end

      it 'has elements composed of hashes' do
        expect(@sf_query.result.first).to be_a Hash
      end

      it 'has hash values that are not arrays' do
        expect(@sf_query.result.first['Id']).to be_a String
      end
    end

    describe 'as_lookup' do
      it 'creates a row lookup based on a key' do
        some_row = @sf_query.result[2]
        expect(@sf_query.as_lookup(key: 'Id')[some_row['Id']]).to eq some_row
      end

      context 'with duplicates' do
        before do
          allow(@sf_query).to receive(:result) { SfBulkHelperStubs.contact_query_duplicated_result }
        end

        it 'returns the first record when duplicates are allowed' do
          first_duplicated_row = @sf_query.result[0]
          expect(@sf_query.as_lookup(key: 'Student_ID__c', duplicates: true)[first_duplicated_row['Student_ID__c']]).to eq first_duplicated_row
        end

        it 'raises an error when duplicates are not allowed' do
          expect { @sf_query.as_lookup(key: 'Student_ID__c') }.to raise_error SfBulkHelper::DupeLookupKeyError
        end
      end
    end

    it 'can query for realz', skip: 'Skip live test' do
      sf_client = SfConnection.new
      q = SfBulkHelper::SfBulkQuery.new(sf_client.client, 'Contact', SfBulkHelperStubs.contact_query)
      puts JSON.pretty_generate(q.raw_result)
    end
  end



  describe SfBulkHelper::SfBulkUpdate do
    before do
      @sf_update = SfBulkHelper::SfBulkUpdate.new({}, 'Contact', SfBulkHelperStubs.contact_update_data, max_attempts: 3)
      allow(@sf_update).to receive(:send_bulk_operation) { SfBulkHelperStubs.contact_update_raw_result }
    end

    describe 'collected result' do
      it 'indicates whether each record was successful' do
        expect(@sf_update.result.map { |r| r.has_key? 'success' }.uniq).to match_array([true])
      end

      it 'indicates whether each record was created' do
        expect(@sf_update.result.map { |r| r.has_key? 'created' }.uniq).to match_array([true])
      end
    end

    describe 'retrying failed records' do
      context 'when the retry fails' do
        before do
          allow(@sf_update).to receive(:send_bulk_operation) { SfBulkHelperStubs.contact_update_with_fail_raw_result }
        end

        it 'raises an error' do
          expect { @sf_update.result }.to raise_error(SfBulkHelper::MaxAttemptError)
        end

        it 'includes only the failed records in the retry attempt' do
          @sf_update.result rescue SfBulkHelper::MaxAttemptError
          retry_data = @sf_update.instance_eval('@data')
          expect(retry_data.size).to eq SfBulkHelperStubs.contact_update_with_fail_raw_result['numberRecordsFailed'].first.to_i
        end
      end

      context 'when the retry is successful' do
        before do
          allow(@sf_update).to receive(:send_bulk_operation).and_return(
            SfBulkHelperStubs.contact_update_with_fail_raw_result,
            SfBulkHelperStubs.contact_update_subsequent_success_raw_result
          )
        end

        it 'stops retrying after success' do
          @sf_update.result
          expect(@sf_update.instance_eval('@attempts[:total]')).to eq 2
        end
      end
    end
  end
end
