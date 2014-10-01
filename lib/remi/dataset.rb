module Remi
  class Dataset

    def initialize(dataset_name, interface)
      @name = dataset_name
      @interface = interface

      # Will also need to initialize
      # RowSet
      # VariableSet
    end

    def delete
      @interface.delete
    end

  end
end
