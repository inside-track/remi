require_relative '../remi_spec'

describe 'sub jobs' do
  before :each do
    Object.send(:remove_const, :MySubJob) if Object.constants.include?(:MySubJob)
    class MySubJob < Job
      source(:sub_source) {}
      target(:sub_target) {}
    end
  end

  let(:sub_job) { Job::SubJob.new { MySubJob.new } }


  describe Extractor::SubJob do
    let(:extractor) { Extractor::SubJob.new(sub_job: sub_job, data_subject: :sub_target) }

    it 'returns the data from the sub-job' do
      allow(sub_job.sub_job.sub_target).to receive(:df) { 'sub target df' }
      expect(extractor.extract).to eq 'sub target df'
    end

    it 'executes the sub job when data is requested' do
      expect(sub_job).to receive(:execute).once
      extractor.extract
    end

  end

  describe Loader::SubJob do
    let(:loader) { Loader::SubJob.new(sub_job: sub_job, data_subject: :sub_source) }

    it 'populates the sub-job data frame' do
      some_data_frame = Daru::DataFrame.new({ a: [1,2,3] })
      loader.load(some_data_frame)
      expect(sub_job.sub_job.sub_source.df).to eq some_data_frame
    end

    it 'autoloads the target' do
      expect(loader.autoload).to be true
    end
  end
end
