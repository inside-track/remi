$LOAD_PATH << '../lib'

require 'rubygems'
require 'bundler/setup'

require 'remi'
require 'benchmark'

require 'time'
require 'stringio'
require 'open3'
include Remi
#Log.level Logger::DEBUG


=begin

Benchmark performance conclusions:

1 - Native Ruby CSV reading isn't great.  It's more than 2x slower
than Kettle.  This may not be acceptable.  Possible solutions are to
look for existing gems that might help or develop a threaded reader
myself.  I really want to stick with using the native Ruby options,
but I don't think I can get away with it if I can't get around this
issue.

2 - Using Remi to read a CSV takes 2x as long as reading the CSV in absence of Remi.
Also, creating an output data set from an input data set takes 10x longer than
it does to just read the data set.  I believe that both of these are a consequence
of a poor job of copying data into a row set.  I'll have to drill into those parts
of the code to determine what's causing this bottleneck.


REMI:
  small:
    remi_read_csv: 49 <- problems moving data from CSV into Remi
    native_read_csv: 24 <- 2x slower than Kettle - can we speed this up?
    split_read_csv: 4.7 <- Simple CSV parsing is much faster (but probably not realistic)
    remi_read_csv_and_write_ds: 128
    remi_read_generated_ds: 6.1
    remi_read_and_write_generated_ds: 79 <- problems moving data from reader to writer?
    remi_read_and_write_generated_ds_separated: 122 <- This increased moving data
    remi_read_and_write_generated_ds_first_row: 20.6 <- So I've definitely got a performance problem with the writer
    remi_read_and_write_generated_ds_no_write: 14
  large:
    remi_read_csv:
    native_read_csv:
    remi_read_csv_and_write_ds:
    remi_read_generated_ds:

KETTLE:
  small:
    read csv: 10.9
    read csv and write csv: 11.7
    read csv and write serialized: 58.4
    read serialized: 45.8
    read serialized and write serialized: 50.7

=end


class Kettle
  class << self

    def kitchen(file: nil, params: nil, logger: Logger.new(STDOUT))
      run_kettle(exe: "/opt/kettle/current/kitchen.sh", file: file, params: params, logger: logger)
    end

    def pan(file: nil, params: nil, logger: Logger.new(STDOUT))
      run_kettle(exe: "/opt/kettle/current/pan.sh", file: file, params: params, logger: logger)
    end

    def run_kettle(exe:, file: nil, params: nil, logger: Logger.new(STDOUT))
      param_string = params.collect { |k,v| "-param:#{k}=#{v}" }.join(' ')
      cmd = "#{exe} -file=#{file} #{param_string}"

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        { :out => stdout, :err => stderr }.each do |key, stream|
          Thread.new do
            until (raw_line = stream.gets).nil? do
              if key == :err
                logger.error raw_line.chomp
              else
                logger.info raw_line.chomp
              end
            end
          end
        end

        wait_thr.join
        raise 'Kettle error' if wait_thr.value != 0
      end

    end
  end

end


class RemiBench

  def worklib
    @worklib ||= DataLib.new(dir_name: "/Users/gnilrets/git/Remi/benchmarks/data")
  end

  def textlib
    @textlib ||= DataLib.new(:delimited_text,
                             dir_name: "/Users/gnilrets/git/Remi/benchmarks/data",
                             csv_opt: {
                               headers: false,
                               col_sep: '|'
                             }
                            )
  end

  def rad_vars
    @rad_vars ||= VariableSet.new do
      var :rad_key, csv_opt: { col: 1 }
      var :distributor_key, csv_opt: { col: 2 }
      var :retailer_key, csv_opt: { col: 3 }
      var :item_key, csv_opt: { col: 4 }
      var :txn_date, csv_opt: { col: 5 }
      var :invoice_nbr, csv_opt: { col: 6 }
      var :outlet_key, csv_opt: { col: 7 }
      var :distributor_sales_rep_key, csv_opt: { col: 8 }
      var :distributor_item_nbr, csv_opt: { col: 9 }
      var :quantity_cases, csv_opt: { col: 10 }
      var :quantity_bottles, csv_opt: { col: 11 }
      var :bottles_per_case, csv_opt: { col: 12 }
      var :physical_cases, csv_opt: { col: 13 }
      var :nine_liters_per_physical_case, csv_opt: { col: 14 }
      var :nine_liter_cases, csv_opt: { col: 15 }
      var :ext_price, csv_opt: { col: 16 }
      var :ext_price_2, csv_opt: { col: 17 }
      var :bottle_deposit_amt, csv_opt: { col: 18 }
      var :tax_amt, csv_opt: { col: 19 }
      var :additional_charges_amt, csv_opt: { col: 20 }
      var :source_file, csv_opt: { col: 21 }
      var :row_hash, csv_opt: { col: 22 }
      var :rpt_current_ind, csv_opt: { col: 23 }
      var :rpt_from_dt, csv_opt: { col: 24 }
      var :rpt_thru_dt, csv_opt: { col: 25 }
    end
  end

  def initialize(*args)
    data = args.shift

    @test_data = case data
                 when 'nano'
                   :'nano_rad.csv'
                 when 'tiny'
                   :'tiny_rad.csv'
                 when 'small'
                   :'small_rad.csv'
                 when 'large'
                   :'large_rad.csv'
                 end

    args.each do |test|
      bench test
    end
  end


  def bench(test)
    result = {}
    time = Benchmark.realtime do
      result = self.send(test)
    end
    puts "\n---------------------------------\n"
    puts "Test: #{test}, Data: #{@test_data}"
    puts "Time: #{time}"
    puts result.select { |k,v| k != :log }.to_yaml
#    puts result[:log]
  end

  def remi_read_csv
    result = {}
    result[:lines] = 0

    ds = textlib[@test_data]
    ds.define_variables do
      like rad_vars
    end

    DataStep.read ds do |ds|
      result[:lines] += 1
    end

    result
  end

  def native_read_csv
    result = {}
    result[:lines] = 0

    file = "#{textlib.dir_name}/#{@test_data}"
    stream = CSV.open(file,'r', headers: false, col_sep: '|')
    loop do
      result[:last_row] = stream.readline
      result[:lines] += 1
      break if stream.eof?
    end
    result[:last_row] = "#{result[:last_row]}"
    result
  end

  def split_read_csv
    result = {}
    result[:lines] = 0

    file = "#{textlib.dir_name}/#{@test_data}"
    stream = CSV.open(file,'r', headers: false, col_sep: '|')
    File.open(file).each_line do |line|
      result[:last_row] = line.split('|')
      result[:lines] += 1
    end
    result[:last_row] = "#{result[:last_row]}"
    result
  end


  def remi_read_csv_and_write_ds
    result = {}
    result[:lines] = 0

    inds = textlib[@test_data]
    inds.define_variables do
      like rad_vars
    end

    outds = worklib.build!(:rad)
    outds.define_variables do
      like rad_vars
    end

    DataStep.create outds do |outds|
      DataStep.read inds do |ds|
        result[:lines] += 1
        outds[] = ds
        outds.write_row
      end
    end

    result
  end


  def remi_read_generated_ds
    result = {}
    result[:lines] = 0

    DataStep.read worklib[:rad] do |ds|
      result[:lines] += 1
    end

    result
  end

  def remi_read_and_write_generated_ds
    result = {}
    result[:lines] = 0

    worklib.build!(:rad2).define_variables do
      like worklib[:rad]
    end

    DataStep.create worklib[:rad2] do |outds|
      DataStep.read worklib[:rad] do |ds|
        result[:lines] += 1
        outds[] = ds
        outds.write_row
      end
    end
    result
  end

  def remi_read_and_write_generated_ds_separated
    # separates reading from writing
    result = {}
    result[:lines] = 0

    array_data = []
    DataStep.read worklib[:rad] do |ds|
      array_data << ds[]
    end

    worklib.build!(:rad2).define_variables do
      like worklib[:rad]
    end

    DataStep.create worklib[:rad2] do |outds|
      array_data.each do |row|
        outds[] = row
        outds.write_row
      end
    end

    result
  end

  def remi_read_and_write_generated_ds_first_row
    # Avoids constantly translating input to output dataset
    result = {}
    result[:lines] = 0

    worklib.build!(:rad2).define_variables do
      like worklib[:rad]
    end

    DataStep.create worklib[:rad2] do |outds|
      DataStep.read worklib[:rad] do |ds|
        result[:lines] += 1
        outds[] = ds if result[:lines] == 1
        puts "#{outds[]}" if result[:lines] == 1
        outds.write_row
      end
    end
    result
  end

  def remi_read_and_write_generated_ds_no_write
    # Goes through all of the steps to write, but does not physically perform the write
    result = {}
    result[:lines] = 0

    worklib.build!(:rad2).define_variables do
      like worklib[:rad]
    end

    var_keys = worklib[:rad].variable_set.keys

    DataStep.create worklib[:rad2] do |outds|
      DataStep.read worklib[:rad] do |ds|
        result[:lines] += 1

#        baseline - no reading variables - 23s/M (vs 11s/M for read only)
#        outds[] = ds # 480%
#        var_keys.each { |v| outds[v] = ds[v] } # 290%
#        outds[:rad_key] = 1 # 12%
#        var_keys.each { |v| ds[v] } # 102%
#        var_keys.each { |v| outds[v] = 1 } # 170%
#        var_keys.each { |v| } # 14%
#        var_keys.each { |v| ds.active_row } # 16%
#        var_keys.each { |v| ds.active_row[v] } # 71%
#        var_keys.each { |v| ds.active_row[*v] } # 71%

#        var_keys.each { |v| v } # 10%
        # the brunt of the problem appears to be this
        # so maybe the problem is that I am trying to work with every single column
        # not really - kettle doesn't have that problem
        var_keys.each { |v| ds[v] }


        outds.write_row if result[:lines] == 1
      end
    end
    result
  end

  def simple_loop
    result = {}
    result[:lines] = 0

    dummy_array = [nil]*25

    dummy_hash = Hash.new
    rad_vars.to_hash.each { |k,v| dummy_hash[k] = nil }

    dummy_row = Row.new([nil]*25, key_map: rad_vars) # row is about as fast as hash

    rad_vars_keys = rad_vars.keys
    array_iter = 0.upto(24).to_a

    100000.times do
      result[:lines] += 1 # 0.1s/M
      # dummy_array.each { |v| v } # 1.4s/M
      # dummy_hash.each { |v| } # 2.6s/M
      # dummy_row.each { |v| v } # 2.2s/M
      # dummy_hash.each { |k, v| } # 1.8s/M # woah, faster when it gets both key and value?

      # I think these all suck because they're doing a sort each time they're called.
      #   - I could possibly improve via memoization.
      # rad_vars.each { |v| } #11s/M
      # rad_vars.each_with_index { |v,i| } #13s/M
      # rad_vars.keys.each { |v| } #15s/M

      # rad_vars_keys.each { |v| } # 1.4s/M
      # rad_vars_keys.each { |v| dummy_row[v] } # 7.1s/M # YEP!  Row access is MUCH slower than hash or array access
      # rad_vars_keys.each { |v| dummy_hash[v] } # 2.3s/M
      # array_iter.each { |v| dummy_array[v] } # 1.7s/M



      # Doing something about access times
      # rad_vars_keys.each { |v| dummy_row[v] } # 6.5s/M # baseline
      # rad_vars_keys.each { |v| dummy_row.get_row_by_map(v) } # 4.7s/M # - so I wonder if there's a way I could permanently set the object to always choose this on initialization!?!?!?!?
      # rad_vars_keys.each { |v| dummy_row.get_row_by_map_simple(v) } # 4.4s/M # - no difference
      rad_vars_keys.each { |v| dummy_row[v] } # 4.7s/M after using singleton method


    end
#    puts dummy_row_as_hash.to_yaml


    result
  end


  def io_test
    result = {}
    result[:lines] = 0

    reader = Interfaces::CanonicalInterface.new(worklib, 'rad')

    header = reader.read_metadata

    reader.open_for_read
    loop do
      result[:lines] += 1
      # reader.read_row(key_map: rad_vars) # 7.3s/M (vs 11s/M within context of data set - due to row set maint?)
      # reader.read_row_light(key_map: rad_vars) # 5.2s/M without creating row object
      # reader.read_row_light # 4.1s/M - so just passing the key_map with every iteration seems to incurr a cost - I should probably figure a way to avoid passing it
      # reader.read_row_memoize(key_map: rad_vars) # 5.5s/M - So avoiding creating a new row object with every line could help out tremendously!
      # break

      # Post row refactoring
      # reader.read_row(key_map: rad_vars) #12s/M
      # reader.read_row_nil #4.0s/M - baseline for for doing nothing but reading the data
      # reader.read_row_key_map_arg(key_map: rad_vars) # 5.1s/M - so just passing the argument adds 25%!
      # reader.read_row_key_map_arg_save_row(key_map: rad_vars) #5.3s/M !!!!! Holy shit awesome! - So I just need to memoize the key map on open and stop creating a row object each step
      # reader.read_row_memoized_key_map #4.1s/M
      reader.read_row # 4.2s/M

      break if reader.eof_flag
    end
    reader.close

    result
  end


  def row_clear_test
    result = {}
    result[:lines] = 0

    row_array = [nil]*25
    row = Row.new(row_array, key_map: rad_vars)

#      var :rad_key, csv_opt: { col: 1 }
#      var :distributor_key, csv_opt: { col: 2 }
#      var :retailer_key, csv_opt: { col: 3 }


#    puts rad_vars[:rad_key, :distributor_key, :item_key, :physical_cases]

#    puts [:rad_key, :distributor_key, :item_key, :physical_cases].collect { |k| rad_vars[k].index }

    0.upto(1000000) do
      result[:lines] += 1
      # row = Row.new(row_array, key_map: rad_vars) # 1.9s/M - before removing key_map tests (via define_singleton)
      # row = Row.new(row_array, key_map: rad_vars) # 6.8s/M
      # row.clear # 0.18s/M
      # row.set_array(row_array) # 0.15s/M
      # row.clear; row.set_array(row_array) # 0.22s/M
      # [nil] * 25 # 0.6s/M
      # Array.new(25) # 0.52s/M
      # row_array.dup # 0.3s/M
      # row_array.clone # 0.3s/M
      # row.clear_with_nils # 0.71s/M
      # row.clear_with_nils_via_dup # 0.41s/M
#      row.set_by_array(nil,row_array)
    end

    result
  end



  def hash_clear_test
    result = {}
    result[:lines] = 0

    h = Hash.new(one: 1, two: 2, three: 3, four: 4, five: 5) #1.2s/M

    0.upto(1000000) do
      result[:lines] += 1
      #      Hash.new(one: 1, two: 2, three: 3, four: 4, five: 5) #1.2s/M
      # 0.3 s/M
      h.clear
      h[:one] = 1
      h[:two] = 2
      h[:three] = 3
      h[:four] = 4
      h[:five] = 5

    end

    result
  end


  # 0.3s/M
  def array_rotate
    result = {}

    off_set_map = {
      -2 => 1,
      -1 => 2,
      0  => 3,
      1  => 4,
      2  => 5
    }

    a = [1,2,3,4,5]
    0.upto(1000000) do
      a.rotate

      a[off_set_map[0]]
    end

    result
  end

  # 0.6s/M - so doing a hash rotate really isn't that bad
  # but when get get up to 100M rows, just rotating the rowset would cost an
  # extra 30 seconds to do it with a hash than to do it with an array
  def hash_rotate
    result = {}

    h = {
      -2 => 1,
      -1 => 2,
      0  => 3,
      1  => 4,
      2  => 5
    }

    0.upto(1000000) do
      h[:x] = h[-2]
      (-2).upto(1) do |i|
        h[i] = h[i+1]

        h[0]
      end
      h[2] = h[:x]
    end

    result
  end

  def pan_benchmark(pan_file: , pan_params: {})
    result = {}

    log_stringio = StringIO.new
    Kettle.pan(
      file: pan_file,
      logger: Logger.new(log_stringio),
      params: pan_params
    )
    log_txt = log_stringio.string

    pan_time_match = /Pan - Start=(\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\.\d*), Stop=(\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}\.\d*)/.match(log_txt)

    result[:lines] = /Dummy \(line_counter\) - Finished processing \(I=\d*, O=\d*, R=(\d*), W=\d*, U=\d*, E=\d*\)/.match(log_txt)[1]

    result[:kettle_time] = Time.parse(pan_time_match[2]) - Time.parse(pan_time_match[1])
    result[:log] = log_txt
    result
  end


  def kettle_read_csv
    pan_benchmark(pan_file: "kettle_benchmark-read.ktr",
                  pan_params: { 'csv_file' => "#{textlib.dir_name}/#{@test_data}" })
  end

  def kettle_read_csv_and_write_csv
    pan_benchmark(pan_file: "kettle_benchmark-read_and_write_csv.ktr",
                  pan_params: { 'csv_file' => "#{textlib.dir_name}/#{@test_data}" })
  end

  def kettle_read_csv_and_write_serialized
    pan_benchmark(pan_file: "kettle_benchmark-read_and_write_serialized.ktr",
                  pan_params: { 'csv_file' => "#{textlib.dir_name}/#{@test_data}" })
  end

  def kettle_read_serialized
    pan_benchmark(pan_file: "kettle_benchmark-read_serialized.ktr",
                  pan_params: { 'csv_file' => "#{textlib.dir_name}/#{@test_data}" })
  end

  def kettle_read_serialized_and_write_serialized
    pan_benchmark(pan_file: "kettle_benchmark-read_serialized_and_write_serialized.ktr",
                  pan_params: { 'csv_file' => "#{textlib.dir_name}/#{@test_data}" })
  end

end


RemiBench.new *ARGV
