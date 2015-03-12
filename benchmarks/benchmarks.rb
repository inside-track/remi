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

2 - Using Remi to read a CSV takes 4x as long as reading the CSV in absence of Remi.
Also, creating an output data set from an input data set takes 5-6x longer than
it does to just read the data set.  I believe that both of these are a consequence
of a poor job of copying data into a row set.  I'll have to drill into those parts
of the code to determine what's causing this bottleneck.


REMI:
  small:
    remi_read_csv: 81.0 <- problems moving data from CSV into Remi
    native_read_csv: 22.5 <- 2x slower than Kettle - can we speed this up?
    split_read_csv: 4.22 <- Simple CSV parsing is much faster (but probably not realistic)
    remi_read_csv_and_write_ds: 187
    remi_read_generated_ds: 10.1
    remi_read_and_write_generated_ds: 87.4 <- problems with writer?
    remi_read_and_write_generated_ds_separated: 122 <- So I don't have a thrashing problem
    remi_read_and_write_generated_ds_first_row: 15.6 <- So I've definitely got a performance problem with copying array/row data into a row
    remi_read_and_write_generated_ds_no_write: 56.0
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
      puts "#{ds[]}" if ds.last_row
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

    DataStep.create worklib[:rad2] do |outds|
      DataStep.read worklib[:rad] do |ds|
        result[:lines] += 1
        outds[] = ds
      end
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
