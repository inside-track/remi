module Remi

  # The Job class is the foundation for all Remi ETL jobs.  It
  # provides a DSL for defining Remi jobs in a way that is natural for
  # ETL style applications.  In a Remi job, the user defines all of
  # the sources, transforms, and targets necessary to transform data.
  # Any number of sources, transforms, and targets can be defined.
  # Transforms can call other parameterized sub-transforms.  Jobs can
  # collect data from other parameterized sub-jobs, pass data to other
  # sub-jobs, or both pass and collect data from other sub-jobs.
  #
  # Jobs are executed by calling the `#execute` method in an instance
  # of the job.  This triggers all transforms to be executed in the
  # order they are defined.  Sub-transforms are only executed if they
  # are referenced in a transform.  After all transforms have
  # executed, the targets are loaded in the order they are defined.
  #
  #
  #
  # @example
  #
  #   class MyJob < Remi::Job
  #     source :my_csv_file do
  #       extractor my_extractor
  #       parser my_parser
  #       enforce_types
  #     end
  #
  #     target :my_transformed_file do
  #       loader my_loader
  #     end
  #
  #     transform :transform_data do
  #       # Data sources are converted into a dataframe the first time the #df method is called.
  #       transform_work = my_csv_file.df.dup # => a copy of the my_csv_file.df dataframe
  #
  #       # Any arbitrary Ruby is allowed in a transform block.  Remi provides a convenient
  #       # source to target map DSL to map fields from sources to targets
  #       Remi::SourceToTargetMap.apply(transform_work, my_transformed_file.df) do
  #         map source(:source_field_id) .target(:prefixed_id)
  #           .transform(->(v) { "PREFIX#{v}" })
  #       end
  #     end
  #   end
  #
  #   # The job is executed when `#execute` is called on an instance of the job.
  #   # Transforms are executed in the order they are defined.  Targets are loaded
  #   # in the order they are defined after all transforms have been executed.
  #   job = MyJob.new
  #   job.execute
  #
  #
  #
  # @todo MOAR Examples!  Subtransforms, subjobs, parameters, references to even more
  #   complete sample jobs.
  class Job
    class << self

      # @return [Job::Parameters] all parameters defined at the class level
      def params
        @params ||= Parameters.new
      end

      # Defines a job parameter.
      # @example
      #
      #   class MyJob < Job
      #     param(:my_param) { 'the best parameter' }
      #   end
      #
      #   job = MyJob.new
      #   job.params[:my_param] #=> 'the best parameter'
      def param(name, &block)
        params.__define__(name, &block)
      end

      # @return [Array<Symbol>] the list of data source names
      def sources
        @sources ||= []
      end

      # Defines a data source.
      # @example
      #
      #   class MyJob < Job
      #     source :my_source do
      #       extractor my_extractor
      #       parser my_parser
      #     end
      #   end
      #
      #   job = MyJob.new
      #   job.my_source.df #=> a dataframe generated after extracting and parsing
      def source(name, &block)
        sources << name unless sources.include? name
        attr_accessor name

        define_method("__init_#{name}__".to_sym) do
          source = DataSource.new(self, name: name, &block)
          instance_variable_set("@#{name}", source)
        end
      end

      # @return [Array<Symbol>] the list of data target names
      def targets
        @targets ||= []
      end

      # Defines a data target.
      # @example
      #
      #   class MyJob < Job
      #     target :my_target do
      #       extractor my_extractor
      #       parser my_parser
      #     end
      #   end
      #
      #   job = MyJob.new
      #   job.my_target.df #=> a dataframe generated after extracting and parsing
      def target(name, &block)
        targets << name unless targets.include? name
        attr_accessor name

        define_method("__init_#{name}__".to_sym) do
          target = DataTarget.new(self, name: name, &block)
          instance_variable_set("@#{name}", target)
        end
      end

      # @return [Array<Symbol>] the list of transform names
      def transforms
        @transforms ||= []
      end

      # Defines a transform.
      # @example
      #
      #   class MyJob < Job
      #     transform :my_transform do
      #       puts "hello from my_transform!"
      #     end
      #   end
      #
      #   job = MyJob.new
      #   job.my_transform.execute #=>(stdout) 'hello from my_transform!'
      def transform(name, &block)
        transforms << name unless transforms.include? name
        attr_accessor name

        define_method("__init_#{name}__".to_sym) do
          transform = Transform.new(self, name: name, &block)
          instance_variable_set("@#{name}", transform)
        end
      end

      # Defines a sub-transform.
      # @example
      #
      #   class MyJob < Job
      #     sub_transform :my_sub_transform, greeting: 'hello' do
      #       puts "#{params[:greeting]} from my_sub_transform!"
      #     end
      #
      #     transform :my_transform do
      #       import :my_sub_transform, greeting: 'bonjour' do
      #       end
      #     end
      #   end
      #
      #   job = MyJob.new
      #   job.my_transform.execute #=>(stdout) 'bonjour from my_sub_transform!'
      def sub_transform(name, **kargs, &block)
        define_method(name) do
          Transform.new(self, name: name, **kargs, &block)
        end
      end
    end

    # Initializes the job
    #
    # @param work_dir [String, Path] sets the working directory for this job
    # @param logger [Object] sets the logger for the job
    # @param kargs [Hash] Optional job parameters (can be referenced in the job via `#params`)
    def initialize(work_dir: Settings.work_dir, logger: Settings.logger, **kargs)
      @work_dir = work_dir
      @logger = logger
      create_work_dir

      __init_params__ **kargs
      __init_sources__
      __init_targets__
      __init_transforms__
    end

    # @return [String] the working directory used for temporary data
    attr_reader :work_dir

    # @return [Object] the logging object
    attr_reader :logger

    # @return [Array] list of sources defined in the job
    attr_reader :sources

    # @return [Array] list of targets defined in the job
    attr_reader :targets

    # @return [Array] list of transforms defined in the job
    attr_reader :transforms

    # @return [Hash] parameters defined at the class level or during instantiation
    attr_reader :params

    # Creates a temporary working directory for the job
    def create_work_dir
      @logger.info "Creating working directory #{work_dir}"
      FileUtils.mkdir_p work_dir
    end


    # @return [self] the job object (needed to reference parent job in transform DSL)
    def job
      self
    end

    # Execute the specified components of the job.
    #
    # @param components [Array<symbol>] list of components to execute (e.g., `:transforms`, `:load_targets`)
    #
    # @return [self]
    def execute(*components)
      execute_transforms if components.empty? || components.include?(:transforms)
      execute_load_targets if components.empty? || components.include?(:load_targets)
      self
    end

    private

    def __init_params__(**kargs)
      @params = self.class.params.clone
      add_params **kargs
      params.context = self
    end

    def __init_transforms__
      @transforms = self.class.transforms
      @transforms.each do |transform|
        send("__init_#{transform}__".to_sym)
      end
    end

    def __init_sources__
      @sources = self.class.sources
      @sources.each do |source|
        send("__init_#{source}__".to_sym)
      end
    end

    def __init_targets__
      @targets = self.class.targets
      @targets.each do |target|
        send("__init_#{target}__".to_sym)
      end
    end


    # Executes all transforms defined
    def execute_transforms
      transforms.map { |t| send(t).execute }
      self
    end

    # Loads all targets defined
    def execute_load_targets
      targets.each { |t| send(t).load }
      self
    end

    # Adds all parameters listed to the job parameters
    def add_params(**kargs)
      kargs.each { |k,v| params[k] = v }
    end





    # A job parameter adds flexiblity to defining job templates.  An
    # instance of Parameters contains a collection of parameters that
    # are evaluatin in the context of a job.  It functions very
    # similarly to Rspec's #let, in that in can be defined using a
    # block of code that is only evaluated the first time it is used,
    # and cached for later use.
    #
    # Parameters should only be used in the context of a job.
    # @example
    #   class MyJob < Remi::Job
    #     param(:my_param) { 'some parameter' }
    #     param :my_calculated_param do
    #       1.upto(1000).size
    #     end
    #
    #     transform :something do
    #       puts "my_param is #{job.params[:my_param]}"
    #       puts "my_calculated_param is #{job.params[:my_calculated_param]}"
    #     end
    #   end
    #
    #   job1 = MyJob.new
    #   job1.execute
    #   #=> my_param is some parameter
    #   #=> my_calculated_param is 1000
    #
    #   job2 = MyJob.new
    #   job2.params[:my_param] = 'override'
    #   job2.execute
    #   #=> my_param is override
    #   #=> my_calculated_param is 1000
    #
    #   job3 = MyJob.new(my_param: 'constructor override', my_calculated_param: 322)
    #   job3.execute
    #   #=> my_param is constructor override
    #   #=> my_calculated_param is 322
    class Parameters
      def initialize(context=nil)
        @context = context
        @params = {}
      end

      # @return [Object] The context in which parameter blocks will be evaluated
      attr_accessor :context

      # Get the value of a parameter
      #
      # @param name [Symbol] The name of the parameter
      #
      # @return [Object] The value of the parameter
      def [](name)
        return send(name) if respond_to?(name)
        raise ArgumentError, "Job parameter #{name} is not defined"
      end


      # Set the value of a parameter
      #
      # @param name [Symbol] The name of the parameter
      # @param value [Object] The new value of the parameter
      #
      # @return [Object] The new value of the parameter
      def []=(name, value)
        __define__(name) { value } unless respond_to? name
        @params[name] = value
      end

      # @return [Hash] The parameters as a hash
      def to_h
        @params
      end

      # @return [Job::Parameters] A clone of this parameter set
      def clone
        the_clone = super
        the_clone.instance_variable_set(:@params, @params.dup)
        the_clone
      end

      def __define__(name, &block)
        @params[name] = nil
        define_singleton_method name do
          @params[name] ||= Remi::Dsl.dsl_return(self, @context, &block)
        end
      end
    end






    # A Transform contains a block of code that is executed in a context.
    # Transforms are usually defined in a Job, according to the Job DSL.
    #
    # Transforms may optionally have a mapping defined that links a
    # local definition of a data frame to a definition of the data
    # frame in the associated context.
    # @example
    #
    #   # Transforms should typically be defined using the Job DSL
    #   job = MyJob.new
    #   tform = Job::Transform.new(job) do
    #     # ... stuff to do in the context of the job
    #   end
    #   tform.execute
    class Transform

      # Initializes a transform
      #
      # @param context [Object, Job] sets the context in which the block will be executed
      # @param name [String, Symbol] optionally gives the transform a name
      # @param kargs [Hash] any keyword arguments are accessable within the block as `#params` (e.g., `params[:my_custom_param]`)
      # @param block [Proc] a block of code to execute in the context
      def initialize(context, name: 'NOT DEFINED', **kargs, &block)
        @context = context
        @name = name
        @block = block
        params.merge! kargs

        @sources = []
        @targets = []
      end

      attr_accessor :context, :name, :sources, :targets

      # Executes the transform block
      # @return [Object] the context of the transform after executing
      def execute
        context.logger.info "Running transformation #{@name}"
        Dsl.dsl_eval(self, @context, &@block)
      end

      # @return [Hash] the parameters defined during initialization of the transform
      def params
        @params ||= Hash.new { |_, key| raise ArgumentError, "Transform parameter #{key} is not defined" }
      end

      # Validates that a data source used in the transform has been defined
      # @param name [Symbol] the name of a data source used in the transform
      # @param fields [Array<Symbol>] a list of fields used by the transform for this data source
      # @raise [ArgumentError] if the transform source is not defined
      def source(name, fields)
        raise ArgumentError, "Need to map fields to source #{name}" unless sources.include? name
      end

      # Validates that a data target used in the transform has been defined
      # @param name [Symbol] the name of a data target used in the transform
      # @param fields [Array<Symbol>] a list of fields used by the transform for this data target
      # @raise [ArgumentError] if the transform target is not defined
      def target(name, fields)
        raise ArgumentError, "Need to map fields to target #{name}" unless targets.include? name
      end

      # Maps data sources and fields from the transform context to the local transform
      # @param from_source [Symbol] name of the source data in the context
      # @param to_source [Symbol] name of the source data local to the transform
      # @param field_maps [Hash] mapping of the key names from the context source to the local source
      def map_source_fields(from_source, to_source, field_maps)
        map_fields(:sources, to_source, from_source, field_maps)
      end

      # Maps data targets and fields from the local tarnsform to the transform context
      # @param from_target [Symbol] name of the target data local to the transform
      # @param to_target [Symbol] name of the target data in the context
      # @param field_maps [Hash] mapping of the key names from the local transform target to the context target
      def map_target_fields(from_target, to_target, field_maps)
        map_fields(:targets, from_target, to_target, field_maps)
      end

      # Imports another transform to be executed as part of this transform.  The block
      # is used to perform any source/target field mapping.
      #
      # @param sub_transform [Job::Transform] the transform to import into this one
      # @param block [Proc] a block of code to be executed prior to the execution of the
      #                     imported transform.  This is where field mapping would be defined.
      # @example
      #
      #   sub_transform = Job::Transform.new('arbitrary') do
      #     source :sub_transform_source, [] # validate that this source has been defined
      #     # do stuff to sub_transform_source here
      #   end
      #
      #   job = MyJob.new
      #   my_transform = Job::Transform.new(job) do
      #     import sub_transform do
      #       map_source_fields :some_method_in_my_job, :sub_sub_transform_source, { :job_id => :sub_transform_id }
      #     end
      #   end
      def import(sub_transform, &block)
        sub_transform.context = context
        Dsl.dsl_eval(sub_transform, self, &block)
        sub_transform.execute
      end

      private

      def map_fields(type, local, remote, fields)
        send(type) << local unless send(type).include? local
        define_singleton_method(local) do
          context.send(remote)
        end
      end
    end

  end
end
