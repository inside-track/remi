module Remi
  class Dataset

    def initialize(dataset_name, interface)
      @name = dataset_name
      @interface = interface

      @variable_set = VariableSet.new
      @row_set = RowSet.new
    end

    attr_reader :variable_set

    def define_variables(vars = [], &block)
      @variable_set.add_vars(vars)
      @variable_set.modify!(&block) if block_given?
    end

    def delete
      @interface.delete
    end

  end
end
