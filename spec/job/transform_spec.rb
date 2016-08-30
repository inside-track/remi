require_relative '../remi_spec'

describe Job do

  before :each do
    Object.send(:remove_const, :MyJob) if Object.constants.include?(:MyJob)
    class MyJob < Job
    end
  end

  let(:job) { MyJob.new }

  describe Job::Transform do
    before do
      class MyJob
        def job_data_subject
          @job_data_subject ||= Remi::DataSubject.new(name: 'job_data_subject')
        end

        def job_data_subject2
          @job_data_subject2 ||= Remi::DataSubject.new(name: 'job_data_subject2')
        end
      end
    end

    let(:my_transform) do
      Job::Transform.new(job, name: 'my_transform name') do
        job_data_subject
      end
    end

    it 'has a name' do
      expect(my_transform.name).to eq 'my_transform name'
    end

    describe '#execute' do
      it 'executes the transform in the context of the job' do
        expect(job).to receive :job_data_subject
        my_transform.execute
      end

      it 'logs a message indicating that the transform is running' do
        expect(job.logger).to receive(:info)
        my_transform.execute
      end
    end

    describe '#map_source_fields' do
      it 'creates a new method in the transform' do
        expect {
          my_transform.map_source_fields(:job_data_subject, :t_source, {})
        }.to change { my_transform.methods.include? :t_source }.from(false).to(true)
      end

      it 'creates a new method representing a data subject' do
        my_transform.map_source_fields(:job_data_subject, :t_source, {})
        expect(my_transform.t_source).to be_a Remi::DataSubject
      end

      it 'adds the linked method to the list of mapped sources' do
        expect {
          my_transform.map_source_fields(:job_data_subject, :t_source, {})
        }.to change { my_transform.sources }.from([]).to([:t_source])
      end

      it 'can add multiple linked methods' do
        my_transform.map_source_fields(:job_data_subject, :t_source, {})
        expect {
          my_transform.map_source_fields(:job_data_subject2, :t_source2, {})
        }.to change { my_transform.sources }.from([:t_source]).to([:t_source, :t_source2])
      end
    end


    describe '#source' do
      context 'without mapping source data' do
        it 'raises a NoMethodError' do
          expect { my_transform.source :t_source, [] }.to raise_error NoMethodError
        end
      end

      context 'without mapping source fields' do
        before { my_transform.map_source_fields(:job_data_subject, :t_source, {}) }
        it 'raises an ArgumentError' do
          expect { my_transform.source :t_source, [:st_field] }.to raise_error ArgumentError
        end
      end

      context 'with mapping source data and fields fields' do
        before { my_transform.map_source_fields(:job_data_subject, :t_source, { :job_field => :st_field }) }
        it 'does not raise an error' do
          expect { my_transform.source :t_source, [:st_field] }.not_to raise_error
        end
      end
    end

    describe '#map_target_fields' do
      it 'creates a new method in the transform' do
        expect {
          my_transform.map_target_fields(:t_target, :job_data_subject, {})
        }.to change { my_transform.methods.include? :t_target }.from(false).to(true)
      end

      it 'creates a new method representing a data subject' do
        my_transform.map_source_fields(:job_data_subject, :t_target, {})
        expect(my_transform.t_target).to be_a Remi::DataSubject
      end

      it 'adds the linked method to the list of mapped targets' do
        expect {
          my_transform.map_target_fields(:t_target, :job_data_subject, {})
        }.to change { my_transform.targets }.from([]).to([:t_target])
      end

      it 'can add multiple linked methods' do
        my_transform.map_target_fields(:t_target, :job_data_subject, {})
        expect {
          my_transform.map_target_fields(:t_target2, :job_data_subject2, {})
        }.to change { my_transform.targets }.from([:t_target]).to([:t_target, :t_target2])
      end
    end

    describe '#target' do
      context 'without mapping source data' do
        it 'raises a NoMethodError' do
          expect { my_transform.target :t_target, [] }.to raise_error NoMethodError
        end
      end

      context 'without mapping target fields' do
        before { my_transform.map_target_fields(:t_target, :job_data_subject, {}) }
        it 'raises an ArgumentError' do
          expect { my_transform.target :t_target, [:st_field] }.to raise_error ArgumentError
        end
      end

      context 'with mapping target data and fields fields' do
        before { my_transform.map_target_fields(:t_target, :job_data_subject, { :st_field => :job_field }) }
        it 'does not raise an error' do
          expect { my_transform.target :t_target, [:st_field] }.not_to raise_error
        end
      end
    end

    describe '#params' do
      let(:my_transform) do
        Job::Transform.new(job, t_param: 'my transform parameter') do
          job_data_subject params[:t_param]
        end
      end

      it 'defines parameters in the constructor' do
        expect(my_transform.params[:t_param]).to eq 'my transform parameter'
      end

      it 'allows parameters to be accessed during execution' do
        expect(job).to receive(:job_data_subject) .with('my transform parameter')
        my_transform.execute
      end

      it 'returns an error if the parameter is not defined' do
        expect { my_transform.params[:unk] }.to raise_error ArgumentError
      end

    end


    # This needs some work.  It's basically a way-too-complicated integration test.
    describe '#import' do
      before do
        class MyJob
          source :job_source do
            fields({ :job_source_field_1 => { type: :date }, :job_source_field_2 => {}})
          end
          target :job_target do
            fields({ :job_target_field_1 => {}, :job_target_field_2 => { from_job: true }})
          end
        end

        job.job_source.df = Remi::DataFrame::Daru.new({
          job_source_field_1: ['something'],
          job_source_field_2: ['else']
        })
      end

      let(:sub_transform) do
        st = Job::Transform.new('arbitrary', name: 'sub_transform', st_param: 'my subtransform parameter') do
          source :st_source, [:st_source_field_1, :st_source_field_2]
          target :st_target, [:st_target_field_1, :st_target_field_2]

          value_of_st_param(params[:st_param])
          Remi::SourceToTargetMap.apply(st_source.df, st_target.df) do
            map source(:st_source_field_1) .target(:st_target_field_1)
            map source(:st_source_field_2) .target(:st_target_field_2)
          end

          st_target.fields[:st_target_field_2] = { from_sub_trans: 'cool' }
        end

        st.define_singleton_method(:value_of_st_param) { |arg| }
        st
      end

      let(:my_transform) do
        scoped_sub_transform = sub_transform
        Job::Transform.new(job, name: 'my_transform') do
          import scoped_sub_transform do
            map_source_fields :job_source, :st_source, {
              :job_source_field_1 => :st_source_field_1,
              :job_source_field_2 => :st_source_field_2
            }
            map_target_fields :st_target, :job_target, {
              :st_target_field_1 => :job_target_field_1,
              :st_target_field_2 => :job_target_field_2

            }
            params[:st_param] = 'modified in parent transform'
          end
        end
      end

      it 'maps source data fields on input' do
        my_transform.execute
        expect(sub_transform.st_source.fields.keys).to eq [:st_source_field_1, :st_source_field_2]
      end

      it 'maps source data vectors on input' do
        my_transform.execute
        expect(sub_transform.st_source.df.vectors.to_a).to eq [:st_source_field_1, :st_source_field_2]
      end

      it 'maps target data fields on output' do
        my_transform.execute
        expect(job.job_target.fields[:job_target_field_2]).to eq({ :from_job => true, :from_sub_trans => "cool" })
      end

      it 'maps target data vectors on output' do
        my_transform.execute
        expect(job.job_target.df.vectors.to_a).to eq [:job_target_field_1, :job_target_field_2]
      end

      it 'executes the sub transform' do
        my_transform.execute
        expect(job.job_target.df.to_a).to eq Remi::DataFrame::Daru.new({
          job_target_field_1: ['something'],
          job_target_field_2: ['else']
        }).to_a

      end

      it 'sets parameters used in the subtransform' do
        expect(sub_transform).to receive(:value_of_st_param) .with('modified in parent transform')
        my_transform.execute
      end
    end
  end
end
