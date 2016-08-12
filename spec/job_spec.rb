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
          param(:my_param) { 'I am my_param' }
        end
      end

      it 'adds a parameter to the parameter hash' do
        expect(job.params.to_h.keys).to include :my_param
      end

      it 'can be accessed at the class level' do
        expect(MyJob.params[:my_param]).to eq 'I am my_param'
      end

      it 'can be accessed at the job level' do
        expect(MyJob.new.params[:my_param]).to eq 'I am my_param'
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

    describe '.source' do
      before do
        class MyJob
          source :my_source do
            'I am a source'
          end
        end
      end

      it 'adds a data source to the list of data sources' do
        expect(job.sources).to eq [:my_source]
      end

      it 'gives the data source a name' do
        expect(job.my_source.name).to eq :my_source
      end

      it 'appends a newly defined data source to the list of data sources' do
        expect {
          class MyJob
            source :my_source2 do
              'I am another source'
            end
          end
        }.to change { job.sources.size }.from(1).to(2)
      end

      it 'does not add the same data source to the list' do
        expect {
          class MyJob
            source :my_source do
              'I am a modified source'
            end
          end
        }.not_to change { job.sources.size }
      end

      it 'returns a data source' do
        expect(job.my_source).to be_a DataSource
      end

      it 'returns a data soruce with the context of the job' do
        expect(job.my_source.context).to eq job
      end
    end

    describe '.target' do
      before do
        class MyJob
          target :my_target do
            'I am a target'
          end
        end
      end

      it 'adds a data target to the list of data targets' do
        expect(job.targets).to eq [:my_target]
      end

      it 'gives the data target a name' do
        expect(job.my_target.name).to eq :my_target
      end

      it 'appends a newly defined data target to the list of data targets' do
        expect {
          class MyJob
            target :my_target2 do
              'I am another target'
            end
          end
        }.to change { job.targets.size }.from(1).to(2)
      end

      it 'does not add the same data target to the list' do
        expect {
          class MyJob
            target :my_target do
              'I am a modified target'
            end
          end
        }.not_to change { job.targets.size }
      end

      it 'returns a data target' do
        expect(job.my_target).to be_a DataTarget
      end

      it 'returns a data soruce with the context of the job' do
        expect(job.my_target.context).to eq job
      end
    end

  end


  context '#params' do
    before do
      class MyJob
        param(:my_param) { 'I am my_param' }
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

        target :target_one do
        end

        target :target_two do
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

    context '#execute(:load_targets)', wip: true do
      it 'loads all targets' do
        [:target_one, :target_two].each do |target_name|
          target = instance_double(DataTarget)
          expect(target).to receive(:load)
          expect(job).to receive(target_name) .and_return(target)
        end

        job.execute(:load_targets)
      end

      it 'does not execute all transforms' do
        expect(job).not_to receive(:execute_transforms)
        job.execute(:load_targets)
      end
    end
  end



  describe Job::Parameters do
    let(:params) { Job::Parameters.new }

    context '#[]' do
      let(:some_method) { double('some_method') }

      before do
        allow(some_method).to receive(:poke) { 'poked' }
        scoped_some_method = some_method
        params.__define__(:my_param) { scoped_some_method.poke }
      end

      it 'fails if the parameter has not been defined' do
        expect { params[:not_defined] }.to raise_error ArgumentError
      end

      it 'returns the evaluated value of the parameter' do
        expect(params[:my_param]).to eq 'poked'
      end

      it 'does not evaluate the parameter block on subsequent calls' do
        expect(some_method).to receive(:poke).once
        params[:my_param]
        params[:my_param]
      end

      it 'evaluates parameters in the context defined' do
        params.__define__(:poke_context) { poke }

        some_context = double('some_context')
        allow(some_context).to receive(:poke) { 'poked some_context' }
        params.context = some_context

        expect(params[:poke_context]).to eq 'poked some_context'
      end
    end

    context '#[]=' do
      it 'set the value of the parameter' do
        params[:my_param] = 'my boring parameter'
        expect(params[:my_param]).to eq 'my boring parameter'
      end

      it 'overwrites an existing parameter' do
        params[:my_param] = 'my boring parameter'
        params[:my_param] = 'my fun parameter'
        expect(params[:my_param]).to eq 'my fun parameter'
      end
    end

    context '#to_h' do
      it 'returns the parameters hash' do
        expect(params.to_h).to be_a Hash
      end
    end

    context '#clone' do
      it 'creates a new parameter hash' do
        new_params = params.clone
        expect(new_params.to_h).not_to be params.to_h
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
