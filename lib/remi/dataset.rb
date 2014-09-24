module Remi
  class Dataset

    def initialize(dataset_name, interface)
      @name = dataset_name
      @interface = interface
    end

    def delete
      @interface.delete
    end

  end
end
