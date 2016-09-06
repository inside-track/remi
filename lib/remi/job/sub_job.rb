module Remi
  class Job
    class SubJob
      def initialize(context=nil, name: 'UNDEFINED SubJob', **kargs, &block)
        @context = context
        @name = name
        @block = block
      end

      attr_accessor :context, :name

      def dsl_return
        sub_job = Dsl.dsl_return(self, @context, &@block)
        raise ArgumentError, "SubJob DSL must return a Remi::Job" unless sub_job.is_a? Job
        sub_job
      end

      def job
        @job ||= dsl_return
      end

      def fields(data_subject)
        job.send(data_subject).dsl_eval.fields
      end

      def execute
        execute! unless @executed
      end

      def execute!
        result = job.execute
        @executed = true
        result
      end

      def execute_transforms
        job.execute(:transforms)
      end
    end
  end
end
