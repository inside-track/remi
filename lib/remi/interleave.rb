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

      sort_keys = Array(by)

      tmplib = Datalib.new :transient => {}

      ds_nil = {}
      datasets.each do |ds|
        logger.debug "DATASET.INTERLEAVE> **#{ds.name}**"

        ds.open_for_read
        ds.initialize_by_groups(sort_keys) if sort_keys.length > 0

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

      # 1 - Read one record from each dataset
      # 2 - Figure out which one should be read next based on by group
      # 3 - Read until end of by group, go back to 2

      puts "BEGIN INTERLEAVE"
      # Initialize by reading one record from each dataset
      ds_sort_key = []
      datasets.each_with_index do |ds,i|
        begin
          ds.read_row
          ds_sort_key << [ds, sort_keys.map { |key| ds[key] }] unless ds.EOF
        rescue EOFError
        end
      end


      datasets_EOF = [false] * datasets.length
      all_EOF = [true] * datasets.length
      i = 0
      while datasets_EOF != all_EOF do
      
        i += 1
        break if i > 100

        puts "Compare rows from each set"
        ds_sort_key.each do |x|
          puts "#{x[0].name} - #{x[0].row}"
        end


        # Sort the datasets by their keys
        puts "ds_sort_key = #{ds_sort_key.collect {|x| x[1]}}"
        if sort_keys != [] 
          ds_sort_key.sort! do |a,b|
            result = nil
            a[1].zip(b[1]).each do |va,vb|
              result = (va <=> vb)
              break unless result == 0
            end
            result
          end
        end

        puts "Sorted result"
        ds_sort_key.each do |x|
          puts "#{x[0].name} - #{x[0].row}"
        end

        puts "Read through the top record until the end of the by group/EOF"
        # Read the top dataset until the end of the by group
        ds = ds_sort_key[0][0]
        first_read = true
        puts "  begining read #{ds.name} - EOF: #{ds.EOF} last: #{ds.last}"
        loop do
          puts "YOU SHOULD ALWAYS SEE ME!"
          begin
            ds.read_row if not first_read
          rescue EOFError
          end
          first_read = false
          puts "Read - #{ds.row} - EOF: #{ds.EOF} last: #{ds.last}"

          break if ds.EOF

          dsi.read_row_from ds
          dsi.name = ds.name
          yield dsi
          dsi.read_row_from ds_nil[ds]

          break if ds.last
        end

        puts "ds.EOF = #{ds.EOF}"
        # Get the next row and put in sort array for sorting
        ds.read_row
        if ds.EOF then
          ds_sort_key.shift
        else
          ds_sort_key[0] = [ds, sort_keys.map { |key| ds[key] }]
        end

        datasets.each_with_index do |ds,i|
          datasets_EOF[i] = ds.EOF
        end

      end

    ensure
      datasets.each do |ds|
        ds.close if ds.is_open?
      end
    end
  end
end
