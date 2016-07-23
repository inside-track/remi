module Remi

  # DataFrame extractor.
  # This class is used to hard-code a dataframe as a simple array of rows.
  #
  # @example
  #
  #   class MyJob < Remi::Job
  #     source :my_df do
  #       fields ({ id: {}, name: {}})
  #       extractor Remi::Extractor::DataFrame.new(
  #         data: [
  #           [1, 'Albert'],
  #           [2, 'Betsy'],
  #           [3, 'Camu']
  #         ]
  #       )
  #       parser Remi::Parser::DataFrame.new
  #     end
  #   end
  #
  #   job = MyJob.new
  #   job.my_df.df.inspect
  #   # =>#<Daru::DataFrame:70153153438500 @name = 4c59cfdd-7de7-4264-8666-83153f46a9e4 @size = 3>
  #   #                    id       name
  #   #          0          1     Albert
  #   #          1          2      Betsy
  #   #          2          3       Camu
  class Extractor::DataFrame < Extractor

    # @param data [Array<Array>] An array of arrays representing rows of a dataframe.
    def initialize(*args, **kargs, &block)
      super
      init_dataframe_extractor(*args, **kargs, &block)
    end

    attr_accessor :data

    # @return [Object] self
    def extract
      self
    end

    private

    def init_dataframe_extractor(*args, data: [], **kargs, &block)
      @data = data
    end

  end

  # DataFrame parser.
  # In order for the DataFrame::Extractor to be parsed correctly, fields must be defined
  # on the data subject.
  #
  # @example
  #
  #   class MyJob < Remi::Job
  #     source :my_df do
  #       fields ({ id: {}, name: {}})
  #       extractor Remi::Extractor::DataFrame.new(
  #         data: [
  #           [1, 'Albert'],
  #           [2, 'Betsy'],
  #           [3, 'Camu']
  #         ]
  #       )
  #       parser Remi::Parser::DataFrame.new
  #     end
  #   end
  #
  #   job = MyJob.new
  #   job.my_df.df.inspect
  #   # =>#<Daru::DataFrame:70153153438500 @name = 4c59cfdd-7de7-4264-8666-83153f46a9e4 @size = 3>
  #   #                    id       name
  #   #          0          1     Albert
  #   #          1          2      Betsy
  #   #          2          3       Camu
  class Parser::DataFrame < Parser
    # @param df_extract [Extractor::DataFrame] An object containing data extracted from memory
    # @return [Remi::DataFrame] The data converted into a dataframe
    def parse(df_extract)
      Remi::DataFrame.create(:daru, df_extract.data.transpose, order: fields.keys)
    end
  end

  # DataFrame encoder
  class Encoder::DataFrame < Encoder
    # @param dataframe [Remi::DataFrame] The dataframe to be encoded
    # @return [Object] The dataframe
    def encode(dataframe)
      dataframe
    end
  end

  # DataFrame loader
  # Not sure this is needed, right?
  # Maybe on SubJobs?
  class Loader::DataFrame < Loader
    # @param data [Encoder::Salesforce] Data that has been encoded appropriately to be loaded into the target
    # @return [true] On success
    def load(data)
      true
    end
  end
end
