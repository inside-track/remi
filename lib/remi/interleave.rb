module Remi

  # Dont think I really need this, since I can get the names from the datasets themselves
  class Interleaver
    include Log
    def initialize(*datasets)
      @datasets = datasets
      @dataset_name = []
      @dataset_full_name = []

      set_names(datasets)
    end

    def set_names(*datasets)
      datasets.each do |ds|
        @dataset_name << ds.name
        @dataset_full_name << "#{ds.datalib}.#{ds.name}"
      end
    end

  end

  module Datastep

    # loop over all datasets, open for reading,
    # compare based on by group, output dataset with name


    def self.interleave(*datasets,by: [],&b)
      datasets.each do |ds|
        logger.debug "DATASET.INTERLEAVE> **#{ds.name}**"

        ds.open_for_read
        ds.initialize_by_groups(by) if by.length > 0
      end

      begin

        datasets_EOF = [false] * datasets.length
        all_EOF = [true] * datasets.length
        while datasets_EOF != all_EOF do
          datasets.each_with_index do |ds,i|
            ds.read_row
            yield ds
            datasets_EOF[i] = ds.EOF
          end
        end
      rescue EOFError
      end

    ensure
      datasets.each do |ds|
        ds.close
      end
    end

  end
end
