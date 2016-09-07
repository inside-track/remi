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
        result = Dsl.dsl_return(self, @context, &@block)
        raise ArgumentError, "SubJob DSL must return a Remi::Job" unless result.is_a? Job
        result
      end

      def sub_job
        @sub_job ||= dsl_return
      end

      def fields(data_subject)
        sub_job.send(data_subject).dsl_eval.fields
      end

      def execute
        execute! unless @executed
      end

      def execute!
        result = sub_job.execute
        @executed = true
        result
      end

      def execute_transforms
        sub_job.execute(:transforms)
      end
    end
  end
end
