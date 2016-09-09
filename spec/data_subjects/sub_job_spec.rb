require_relative '../remi_spec'

describe 'sub jobs' do
  before :each do
    Object.send(:remove_const, :MySubJob) if Object.constants.include?(:MySubJob)
    class MySubJob < Job
      source :sub_source do
        fields({ a: { from_sub_job: true, to_overwrite: 'from_sub_job' } })
      end
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
    let(:data_target) { DataTarget.new }
    let(:loader) { Loader::SubJob.new(context: data_target, sub_job: sub_job, data_subject: :sub_source) }
    let(:my_data_frame) { Daru::DataFrame.new({ a: [1,2,3] }) }

    it 'populates the sub-job data frame' do
      loader.load(my_data_frame)
      expect(sub_job.sub_job.sub_source.df).to eq my_data_frame
    end

    it 'merges fields from the parent source when requested' do
      data_target.fields({ a: { from_parent: :true, to_overwrite: 'from_parent' } })
      loader.load(my_data_frame)
      expect(sub_job.sub_job.sub_source.fields).to eq MySubJob.new.sub_source.fields.merge data_target.fields
    end

    it 'does not merge fields from the parent source when requested' do
      loader.merge_fields = false
      data_target.fields({ a: { from_parent: :true, to_overwrite: 'from_parent' } })
      loader.load(my_data_frame)
      expect(sub_job.sub_job.sub_source.fields).to eq MySubJob.new.sub_source.fields
    end

    it 'autoloads the target' do
      expect(loader.autoload).to be true
    end
  end
end
