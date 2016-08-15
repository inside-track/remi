module Remi
  class Job
    class SubJob
      def initialize(context=nil, name: 'UNDEFINED SubJob', **kargs, &block)
        @context = context
        @name = name
        @block = block
        @job = dsl_return
      end

      attr_accessor :context, :name, :job

      def dsl_return
        sub_job = Dsl.dsl_return(self, @context, &@block)
        raise ArgumentError, "SubJob DSL must return a Remi::Job" unless sub_job.is_a? Job
        sub_job
      end

      def execute
        job.execute
      end

      def execute_transforms
        job.execute(:transforms)
      end
    end
  end
end
