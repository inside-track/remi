module Remi

  # @api private
  #
  # A namespace for functions relating to the execution of a block against a
  # proxy object.
  #
  # Much of this code was borrowed from [Docile](https://github.com/ms-ati/docile)
  # and was modified to support different fallback contexts.
  # @see Docile [Docile](https://github.com/ms-ati/docile)

  module Dsl
    # Execute a block in the context of an object whose methods represent the
    # commands in a DSL, using a specific proxy class.
    #
    # @param dsl          [Object] context object whose methods make up the
    #                              (initial) DSL
    # @param fallback_dsl [Object] context object that the DSL should fall back
    #                              to if the primary context fails to resolve
    # @param proxy_type   [FallbackContextProxy, ChainingFallbackContextProxy]
    #                              which class to instantiate as proxy context
    # @param args         [Array]  arguments to be passed to the block
    # @param block        [Proc]   the block of DSL commands to be executed
    # @return             [Object] the return value of the block

    def exec_in_proxy_context(dsl, fallback_dsl, proxy_type, *args, &block)
      block_context = fallback_dsl
      proxy_context = proxy_type.new(dsl, block_context)
      begin
        block_context.instance_variables.each do |ivar|
          value_from_block = block_context.instance_variable_get(ivar)
          proxy_context.instance_variable_set(ivar, value_from_block)
        end
        proxy_context.instance_exec(*args, &block)
      ensure
        block_context.instance_variables.each do |ivar|
          value_from_dsl_proxy = proxy_context.instance_variable_get(ivar)
          block_context.instance_variable_set(ivar, value_from_dsl_proxy)
        end
      end
    end
    module_function :exec_in_proxy_context


    # Execute a block in the context of an object whose methods represent the
    # commands in a DSL.
    #
    # @note Use with an *imperative* DSL (commands modify the context object)
    #
    # Use this method to execute an *imperative* DSL, which means that:
    #
    #   1. Each command mutates the state of the DSL context object
    #   2. The return value of each command is ignored
    #   3. The final return value is the original context object
    #
    #
    # @param dsl            [Object] context object whose methods make up the DSL
    # @param fallback_dsl   [Object] context object that the DSL should fallback to
    # @param args           [Array]  arguments to be passed to the block
    # @param block          [Proc]   the block of DSL commands to be executed against the
    #                                `dsl` context object
    # @return               [Object] the `dsl` context object after executing the block
    def dsl_eval(dsl, fallback_dsl, *args, &block)
      exec_in_proxy_context(dsl, fallback_dsl, Docile::FallbackContextProxy, *args, &block)
      dsl
    end
    module_function :dsl_eval
  end
end
