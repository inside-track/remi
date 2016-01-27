module Remi
  module Job
    module JobClassMethods
      attr_accessor :params
      attr_accessor :lookups
      attr_accessor :sources
      attr_accessor :targets
      attr_accessor :transforms

      def define_param(key, value)
        @params ||= {}
        @params[key] = value
      end

      def define_lookup(name, type_class, options)
        @lookups ||= []
        @lookups << name

        define_method(name) do
          iv_name = instance_variable_get("@#{name}")
          return iv_name if iv_name

          if type_class == Hash
            lookup = options
          else
            lookup = type_class.new(options)
          end
          instance_variable_set("@#{name}", lookup)
        end
      end

      def define_source(name, type_class, **options)
        @sources ||= []
        @sources << name

        define_method(name) do
          iv_name = instance_variable_get("@#{name}")
          return iv_name if iv_name

          source = type_class.new(options)
          instance_variable_set("@#{name}", source)
        end
      end

      def define_target(name, type_class, **options)
        @targets ||= []
        @targets << name

        define_method(name) do
          iv_name = instance_variable_get("@#{name}")
          return iv_name if iv_name

          target = type_class.new(options)
          instance_variable_set("@#{name}", target)
        end
      end

      def define_transform(name, sources: [], targets: [], &block)
        @transforms ||= {}
        @transforms[name] = { sources: Array(sources), targets: Array(targets) }

        define_method(name) do
          instance_eval { @logger.info "Running transformation #{__method__}" }
          instance_eval(&block)
        end
      end

      def params
        @params || {}
      end

      def lookups
        @lookups || []
      end

      def sources
        @sources || []
      end

      def targets
        @targets || []
      end

      def transforms
        @transforms || {}
      end


      def work_dir
        Settings.work_dir
      end

      def self.extended(receiver)
      end

      def included(receiver)
        receiver.extend(JobClassMethods)
        receiver.params     = self.params.merge(receiver.params)
        receiver.lookups    = self.lookups + receiver.lookups
        receiver.sources    = self.sources + receiver.sources
        receiver.targets    = self.targets + receiver.targets
        receiver.transforms = self.transforms.merge(receiver.transforms)
      end
    end

    def self.included(receiver)
      receiver.extend(JobClassMethods)
    end


    def params
      self.class.params
    end

    def lookups
      self.class.lookups
    end

    def sources
      self.class.sources
    end

    def targets
      self.class.targets
    end

    def transforms
      self.class.transforms
    end



    def initialize(runtime_params: {}, delete_work_dir: true, logger: Settings.logger)
      @runtime_params = runtime_params
      @delete_work_dir = delete_work_dir
      @logger = logger
      create_work_dir
    end

    attr_accessor :runtime_params

    def work_dir
      self.class.work_dir
    end

    def finalize
      delete_work_dir
    end

    def delete_work_dir
      if @delete_work_dir && (work_dir.match /^#{Dir.tmpdir}/)
        @logger.info "Deleting temporary directory #{work_dir}"
        FileUtils.rm_r work_dir
      else
        @logger.debug "Not going to delete working directory #{work_dir}"
        nil
      end
    end

    def create_work_dir
      @logger.info "Creating working directory #{work_dir}"
      FileUtils.mkdir_p work_dir
    end

    # Public: Runs any transforms that use the sources and targets selected.  If
    # source and target is not specified, then all transforms will be run.
    # If only the source is specified, then all transforms that use any of the
    # sources will be run.  Same for specified transforms.
    #
    # sources - Array of source names
    # targets - Array of target names
    #
    # Returns an array containing the result of each transform.
    def run_transforms_using(sources: nil, targets: nil)
      transforms.map do |t, st|
        selected_sources = (st[:sources] & Array(sources || st[:sources])).size > 0
        selected_targets = (st[:targets] & Array(targets || st[:targets])).size > 0
        self.send(t) if selected_sources && selected_targets
      end
    end

    def run_all_transforms
      transforms.map { |t, st| self.send(t) }
    end

    def load_all_targets
      targets.each do |target|
        @logger.info "Loading target #{target}"
        self.send(target).tap { |t| t.respond_to?(:load) ? t.load : nil }
      end
    end

    # Public: Runs all transforms defined in the job.
    #
    # Returns the job instance.
    def run
      # Do all of the stuff here
      run_all_transforms
      load_all_targets
      self
    end
  end
end
