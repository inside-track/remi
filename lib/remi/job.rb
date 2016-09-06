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

      def inherited(base)
        base.instance_variable_set(:@params, params.clone)
        base.instance_variable_set(:@sources, sources.dup)
        base.instance_variable_set(:@targets, targets.dup)
        base.instance_variable_set(:@transforms, transforms.dup)
        base.instance_variable_set(:@sub_jobs, sub_jobs.dup)
      end

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


      # @return [Array<Symbol>] the list of sub-jobs
      def sub_jobs
        @sub_jobs ||= []
      end

      # Defines a sub job resource for this job.
      # Note that the return value of the DSL block must be an instance of a Remi::Job
      # @example
      #
      #   class MyJob < Job
      #     sub_job(:my_sub_job) { MySubJob.new }
      #   end
      #
      #   job = MyJob.new
      #   job.sub_job.job #=> An instance of MySubJob
      def sub_job(name, &block)
        sub_jobs << name unless sub_jobs.include? name
        attr_accessor name

        define_method("__init_#{name}__".to_sym) do
          sub_job = Job::SubJob.new(self, name: name, &block)
          instance_variable_set("@#{name}", sub_job)
        end
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
      __init_sub_jobs__
      __init_sources__
      __init_targets__
      __init_transforms__
    end

    # @return [String] the working directory used for temporary data
    attr_reader :work_dir

    # @return [Object] the logging object
    attr_reader :logger

    # @return [Job::Parameters] parameters defined at the class level or during instantiation
    attr_reader :params

    # @return [Array] list of sub_jobs defined in the job
    attr_reader :sub_jobs

    # @return [Array] list of sources defined in the job
    attr_reader :sources

    # @return [Array] list of targets defined in the job
    attr_reader :targets

    # @return [Array] list of transforms defined in the job
    attr_reader :transforms


    # Creates a temporary working directory for the job
    def create_work_dir
      @logger.info "Creating working directory #{work_dir}"
      FileUtils.mkdir_p work_dir
    end


    # @return [self] the job object (needed to reference parent job in transform DSL)
    def job
      self
    end

    def to_s
      inspect
    end

    def inspect
      "#<#{Remi::Job}>: #{self.class}\n" +
        "  parameters: #{params.to_h.keys}\n" +
        "  sources: #{sources}\n" +
        "  targets: #{targets}\n" +
        "  transforms: #{transforms}\n" +
        "  sub_jobs: #{sub_jobs}"
    end


    # Execute the specified components of the job.
    #
    # @param components [Array<symbol>] list of components to execute (e.g., `:transforms`, `:load_targets`)
    #
    # @return [self]
    def execute(*components)
      execute_transforms if components.empty? || components.include?(:transforms)
      execute_sub_jobs if components.empty? || components.include?(:sub_jobs)
      execute_load_targets if components.empty? || components.include?(:load_targets)
      self
    end

    private

    def __init_params__(**kargs)
      @params = self.class.params.clone
      add_params **kargs
      params.context = self
    end

    def __init_sub_jobs__
      @sub_jobs = self.class.sub_jobs
      @sub_jobs.each do |sub_job|
        send("__init_#{sub_job}__".to_sym)
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

    def __init_transforms__
      @transforms = self.class.transforms
      @transforms.each do |transform|
        send("__init_#{transform}__".to_sym)
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

    # Executes all subjobs (not already executed)
    def execute_sub_jobs
      sub_jobs.each { |sj| send(sj).execute }
      self
    end

    # Adds all parameters listed to the job parameters
    def add_params(**kargs)
      kargs.each { |k,v| params[k] = v }
    end
  end
end
