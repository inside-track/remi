module Remi
  class Job
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
        @params_methods = []
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

        value
      end

      # @return [Hash] The evaluated parameters as a hash
      def to_h
        @params_methods.each { |p| self.send(p) }
        @params
      end

      # @return [Job::Parameters] A clone of this parameter set
      def clone
        the_clone = super
        the_clone.instance_variable_set(:@params, @params.dup)
        the_clone.instance_variable_set(:@params_methods, @params_methods.dup)
        the_clone
      end

      def __define__(name, &block)
        @params_methods << name unless @params_methods.include? name
        define_singleton_method name do
          @params.fetch(name) { |name| @params[name] = Remi::Dsl.dsl_return(self, @context, &block) }
        end
      end
    end
  end
end
