module Remi

  class DataSource::DataFrame < DataSource

    def initialize(*args, **kargs, &block)
      super
      init_df(*args, **kargs, &block)
    end

    # Public: Called to extract data from the source.
    #
    # Returns data in a format that can be used to create a dataframe.
    def extract!
      @extract = @data.transpose
    end

    # Public: Converts extracted data to a dataframe
    #
    # Returns a Remi::DataFrame
    def to_dataframe
      DataFrame.create(@remi_df_type, extract, order: @fields.keys)
    end

    private

    def init_df(*args, data: [], **kargs, &block)
      @data = data
    end
  end


  class DataTarget::DataFrame < DataTarget

    def initialize(*args, **kargs, &block)
      super
      init_df(*args, **kargs, &block)
    end

    # Public: Performs the load operation, regardless of whether it has
    # already executed.
    #
    # Returns true if the load operation was successful
    def load!
      true
    end

    private

    def init_df(*args, **kargs, &block)
    end
  end
end
