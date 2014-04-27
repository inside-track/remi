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

      tmplib = Datalib.new :transient => {}

      ds_nil = {}
      datasets.each do |ds|
        logger.debug "DATASET.INTERLEAVE> **#{ds.name}**"

        ds.open_for_read
        ds.initialize_by_groups(Array(by)) if Array(by).length > 0

        ds_nil[ds] = tmplib.send(ds.name)
        Variables.define ds_nil[ds] do |v|
          v.import ds
        end
      end

      # Interleaved row holder
      dsi = tmplib.dsi
      Variables.define dsi do |v|
        datasets.each do |ds|
          v.import ds
        end
      end

      # Allow for overriding the name for the interleaved dataset
      def dsi.name=(name)
          @name=name
      end
        
      begin
        datasets_EOF = [false] * datasets.length
        all_EOF = [true] * datasets.length
        while datasets_EOF != all_EOF do
          datasets.each_with_index do |ds,i|
            ds.read_row
            dsi.read_row_from ds
            dsi.name = ds.name
            datasets_EOF[i] = ds.EOF
            next if ds.EOF
            yield dsi
            dsi.read_row_from ds_nil[ds]
          end
        end
      rescue EOFError
      end

    ensure
      datasets.each do |ds|
        ds.close if ds.is_open?
      end
    end
  end
end
