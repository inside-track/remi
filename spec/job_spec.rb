require_relative 'remi_spec'

describe Job do

  before :each do
    Object.send(:remove_const, :MyJob) if Object.constants.include?(:MyJob)
    class MyJob < Job
    end

    Object.send(:remove_const, :MySubJob) if Object.constants.include?(:MySubJob)
    class MySubJob < Job
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

    describe '.sub_job' do
      before do
        class MyJob
          sub_job(:my_sub_job) { MySubJob.new }
        end
      end

      it 'adds the sub-job to the list of sub-jobs' do
        expect(job.sub_jobs).to eq [:my_sub_job]
      end

      it 'gives the sub-job a name' do
        expect(job.my_sub_job.name).to eq :my_sub_job
      end

      it 'appends a newly defined sub-job to the list of sub-jobs' do
        expect {
          class MyJob
            sub_job(:my_sub_job2) { MySubJob.new }
          end
        }.to change { job.sub_jobs.size }.from(1).to(2)
      end

      it 'does not add the same sub-job to the list' do
        expect {
          class MyJob
            sub_job(:my_sub_job) { MySubJob.new }
          end
        }.not_to change { job.sub_jobs.size }
      end

      it 'raises an error if the return value is not a Remi job' do
        class MyJob
          sub_job(:my_sub_job) { 'something' }
        end
        expect { job.my_sub_job.job }.to raise_error ArgumentError
      end

      it 'returns a Remi job' do
        expect(job.my_sub_job.job).to be_a Remi::Job
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

      it 'does not require a block' do
        class MyJob
          source :another_source
        end
        expect(job.sources).to include :another_source
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

      it 'does not require a block' do
        class MyJob
          target :another_target
        end
        expect(job.targets).to include :another_target
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

    context '#execute(:load_targets)' do
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

  context 'inheritance' do
    before do
      Object.send(:remove_const, :MyInheritedJob) if Object.constants.include?(:MyInheritedJob)
      class MyJob
        param(:my_param) { 'I am my_param' }
        source :my_source
        target :my_target
        transform(:my_transform) { }
        sub_job(:my_sub_job) { }
      end

      class MyInheritedJob < MyJob; end
    end

    it 'inherits a copy of the job parameters' do
      expect(MyInheritedJob.params.to_h.keys).to eq [:my_param]
      expect(MyInheritedJob.params.object_id).not_to eq MyJob.params.object_id
    end

    it 'inherits a copy of the sources' do
      expect(MyInheritedJob.sources).to eq [:my_source]
      expect(MyInheritedJob.sources.object_id).not_to eq MyJob.sources.object_id
    end

    it 'inherits a copy of the targets' do
      expect(MyInheritedJob.targets).to eq [:my_target]
      expect(MyInheritedJob.targets.object_id).not_to eq MyJob.targets.object_id
    end

    it 'inherits a copy of the transforms' do
      expect(MyInheritedJob.transforms).to eq [:my_transform]
      expect(MyInheritedJob.transforms.object_id).not_to eq MyJob.transforms.object_id
    end

    it 'inherits a copy of the sub_jobs' do
      expect(MyInheritedJob.sub_jobs).to eq [:my_sub_job]
      expect(MyInheritedJob.sub_jobs.object_id).not_to eq MyJob.sub_jobs.object_id
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



  describe Job::SubJob do
    let(:sub_job) { MySubJob.new }
    let(:job_sub_job) do
      scoped_sub_job = sub_job
      Job::SubJob.new { scoped_sub_job }
    end

    context '#job' do
      it 'returns the job instance for the sub job' do
        expect(job_sub_job.job).to eq sub_job
      end
    end

    context '#fields' do
      before do
        class MySubJob
          source :some_source do
            fields({ :some_field => {} })
          end
        end
      end

      it 'gets the fields from the specified data subject' do
        expect(job_sub_job.fields(:some_source)).to eq({ :some_field => {} })
      end
    end

    context '#execute' do
      it 'executes the sub job' do
        expect(sub_job).to receive(:execute)
        job_sub_job.execute
      end
    end

    context '#execute_transforms' do
      it 'executes the sub job transforms' do
        expect(sub_job).to receive(:execute) .with(:transforms)
        job_sub_job.execute_transforms
      end
    end
  end

end
