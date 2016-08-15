module Remi
  class Job
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
