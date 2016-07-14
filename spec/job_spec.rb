require_relative 'remi_spec'

describe Job do

  before :each do
    Object.send(:remove_const, :MyJob) if Object.constants.include?(:MyJob)
    class MyJob < Job
    end
  end

  let(:job) { MyJob.new }


  context 'DSL' do
    describe '.param' do
      before do
        class MyJob
          param :my_param, 'I am my_param'
        end
      end

      it 'adds a parameter to the parameter hash' do
        expect(job.params.keys).to include :my_param
      end
    end

    describe '.transform' do
      before do
        class MyJob
          transform :my_transform do
            'I am a transform'
          end
        end
      end

      it 'adds a transform to the list of transforms' do
        expect(job.transforms).to eq [:my_transform]
      end

      it 'gives the transform a name' do
        expect(job.my_transform.name).to eq :my_transform
      end

      it 'appends a newly defined transform to the list of transforms' do
        expect {
          class MyJob
            transform :my_transform2 do
              'I am another transform'
            end
          end
        }.to change { job.transforms.size }.from(1).to(2)
      end

      it 'does not add the same transform to the list' do
        expect {
          class MyJob
            transform :my_transform do
              'I am a modified transform'
            end
          end
        }.not_to change { job.transforms.size }
      end

      it 'returns a transform' do
        expect(job.my_transform).to be_a Job::Transform
      end

      it 'returns a transform with the context of the job' do
        expect(job.my_transform.context).to eq job
      end

    end

    describe '.sub_transform' do
      before do
        class MyJob
          sub_transform :my_sub_transform do
            'I am a sub_transform'
          end
        end
      end

      it 'does not add a transform to the list of transforms' do
        expect(job.transforms.size).to eq 0
      end

      it 'returns a transform' do
        expect(job.my_sub_transform).to be_a Job::Transform
      end

      it 'returns a transform with the context of the job' do
        expect(job.my_sub_transform.context).to eq job
      end
    end

  end

  context '#params' do
    before do
      class MyJob
        param :my_param, 'I am my_param'
      end
    end

    context 'defined as part of class definition' do
      it 'raises an error when the parameter is not defined' do
        expect { job.params[:other_param] }.to raise_error ArgumentError
      end
    end

    context 'defined at instantiation' do
      let(:job) { MyJob.new(my_param: 'instantiated') }

      it 'has a value that can be overwritten' do
        expect(job.params[:my_param]).to eq 'instantiated'
      end

      it 'does not affect the values of other instances' do
        job
        other_job = MyJob.new
        expect(other_job.params[:my_param]).to eq 'I am my_param'
      end
    end
  end

  context '#work_dir', skip: 'TODO' do
    it 'does something awesome'
  end

  context '#logger', skip: 'TODO' do
    it 'does something awesome'
  end

  context '#execute' do
    before do
      class MyJob
        transform :transform_one do
        end

        transform :transform_two do
        end
      end
    end

    it 'executes all transforms' do
      expect(job).to receive(:execute_transforms)
      job.execute
    end

    it 'executes load all targets' do
      expect(job).to receive(:execute_load_targets)
      job.execute
    end

    context '#execute(:transforms)' do
      it 'executes all transforms' do
        [:transform_one, :transform_two].each do |tform_name|
          tform = instance_double(Job::Transform)
          expect(tform).to receive(:execute)
          expect(job).to receive(tform_name) .and_return(tform)
        end

        job.execute(:transforms)
      end

      it 'does not load all targets' do
        expect(job).not_to receive(:execute_load_targets)
        job.execute(:transforms)
      end
    end

    context '#execute(:load_targets)', skip: 'TODO' do
      it 'loads all targets'

      it 'does not execute all transforms' do
        expect(job).not_to receive(:execute_transforms)
        job.execute
      end
    end
  end


  describe Job::Transform do
    before do
      class MyJob
        def some_method_in_my_job
          'some_method_in_my_job result'
        end
      end
    end

    let(:my_transform) do
      Job::Transform.new(job, name: 'my_transform name') do
        some_method_in_my_job
      end
    end

    it 'has a name' do
      expect(my_transform.name).to eq 'my_transform name'
    end

    describe '#execute' do
      it 'executes the transform in the context of the job' do
        expect(job).to receive :some_method_in_my_job
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
          my_transform.map_source_fields(:some_method_in_my_job, :t_source, {})
        }.to change { my_transform.methods.include? :t_source }.from(false).to(true)
      end

      it 'links a method in the transform to a method in the parent context' do
        my_transform.map_source_fields(:some_method_in_my_job, :t_source, {})
        expect(my_transform.t_source).to eq 'some_method_in_my_job result'
      end

      it 'adds the linked method to the list of mapped sources' do
        expect {
          my_transform.map_source_fields(:some_method_in_my_job, :t_source, {})
        }.to change { my_transform.sources }.from([]).to([:t_source])
      end

      it 'can add multiple linked methods' do
        my_transform.map_source_fields(:some_method_in_my_job, :t_source, {})
        expect {
          my_transform.map_source_fields(:some_method_in_my_job2, :t_source2, {})
        }.to change { my_transform.sources }.from([:t_source]).to([:t_source, :t_source2])
      end
    end

    describe '#source' do
      context 'without mapping source fields' do
        it 'raises an ArgumentError' do
          expect { my_transform.source :t_source, [] }.to raise_error ArgumentError
        end
      end

      context 'with mapping source fields' do
        before { my_transform.map_source_fields(:some_method_in_my_job, :t_source, {}) }
        it 'does not raise an error' do
          expect { my_transform.source :t_source, [] }.not_to raise_error
        end
      end
    end

    describe '#map_target_fields' do
      it 'creates a new method in the transform' do
        expect {
          my_transform.map_target_fields(:t_target, :some_method_in_my_job, {})
        }.to change { my_transform.methods.include? :t_target }.from(false).to(true)
      end

      it 'links a method in the transform to a method in the parent context' do
        my_transform.map_target_fields(:t_target, :some_method_in_my_job, {})
        expect(my_transform.t_target).to eq 'some_method_in_my_job result'
      end

      it 'adds the linked method to the list of mapped targets' do
        expect {
          my_transform.map_target_fields(:t_target, :some_method_in_my_job, {})
        }.to change { my_transform.targets }.from([]).to([:t_target])
      end

      it 'can add multiple linked methods' do
        my_transform.map_target_fields(:t_target, :some_method_in_my_job, {})
        expect {
          my_transform.map_target_fields(:t_target2, :some_method_in_my_job2, {})
        }.to change { my_transform.targets }.from([:t_target]).to([:t_target, :t_target2])
      end
    end

    describe '#target' do
      context 'without mapping target fields' do
        it 'raises an ArgumentError' do
          expect { my_transform.source :t_target, [] }.to raise_error ArgumentError
        end
      end

      context 'with mapping target fields' do
        before { my_transform.map_target_fields(:t_target, :some_method_in_my_job, {}) }
        it 'does not raise an error' do
          expect { my_transform.target :t_target, [] }.not_to raise_error
        end
      end
    end

    describe '#params' do
      let(:my_transform) do
        Job::Transform.new(job, t_param: 'my transform parameter') do
          some_method_in_my_job params[:t_param]
        end
      end

      it 'defines parameters in the constructor' do
        expect(my_transform.params[:t_param]).to eq 'my transform parameter'
      end

      it 'allows parameters to be accessed during execution' do
        expect(job).to receive(:some_method_in_my_job) .with('my transform parameter')
        my_transform.execute
      end

      it 'returns an error if the parameter is not defined' do
        expect { my_transform.params[:unk] }.to raise_error ArgumentError
      end

    end


    describe '#import' do
      let(:sub_transform) do
        st = Job::Transform.new('arbitrary', st_param: 'my subtransform parameter') do
          source :st_source, []

          value_of_st_param(params[:st_param])
          st_source
        end

        st.define_singleton_method(:value_of_st_param) { |arg| }
        st
      end

      let(:my_transform) do
        scoped_sub_transform = sub_transform
        Job::Transform.new(job) do
          import scoped_sub_transform do
            map_source_fields :some_method_in_my_job, :st_source, []
            params[:st_param] = 'modified in parent transform'
          end
        end
      end

      it 'adds a transform within another transform that executes in the context of the job' do
        expect(job).to receive(:some_method_in_my_job)
        my_transform.execute
      end

      it 'sets parameters used in the subtransform' do
        expect(sub_transform).to receive(:value_of_st_param) .with('modified in parent transform')
        my_transform.execute
      end
    end
  end
end
