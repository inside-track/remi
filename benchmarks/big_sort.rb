$LOAD_PATH << '../lib'

require 'rubygems'
require 'bundler/setup'

require 'remi'
require 'benchmark'

include Remi
Log.level Logger::DEBUG

# Kettle results:
#  CSV to serialize RAD
#    1M records: 00:47
#    17.8M records: 11:18
#  Deserialize to serialize
#    1M records: 00:47
#  Deserialize and sort
#    1M records / 1M in memory: 01:14
#    1M records / 100K in memrory: 01:07
#    17.8M records: 22:20

# Remi Results
# CSV to dataset
#   1M records: 00:46
# Read and write, no transformation
#   1M records: 00:25
# Sort
#   1M records / 100K in memory: 03:05
#   1M records / 1M in memory: 01:34
#   1M records / 500K in memory: 03:05
#
#   - hmmm..... so it might be that my interleave algorithm sucks, or it could
#   just be that it requires an additional write/read
#
#   1M records / 100K in memory, no interleave: 01:05
#   SO! Interleave sucks!  Good to know!

worklib = Datalib.new :directory => { :dirname => "/Users/gnilrets/Desktop" }
rad_full_path = "/Users/gnilrets/Desktop/RAD_1m.csv"

=begin
Datastep.create worklib.rad do |ds|
  Variables.define ds do |v|
    v.create :Transaction_Type, :type => "string", :csv_col => 0
    v.create :Record_Creation_Date, :type => "string", :csv_col => 1
    v.create :Item_Number, :type => "string", :csv_col => 2
    v.create :Distributor_Key, :type => "string", :csv_col => 3
    v.create :Retailer_Ext_Key, :type => "string", :csv_col => 4
    v.create :Date_of_Data, :type => "string", :csv_col => 5
    v.create :Physical_Cases, :type => "number", :csv_col => 6
    v.create :Extended_Price, :type => "number", :csv_col => 7
    v.create :NineLiter_Cases, :type => "number", :csv_col => 8
    v.create :Standard_Cases, :type => "number", :csv_col => 9
  end

  i = 0
  CSV.datastep rad_full_path do |row|
    i += 1
    next if i == 1 
    ds.read_row_from_csv(row)
    ds.write_row
  end
end
=end

time = Benchmark.realtime do
  Datastep.sort worklib.rad, out: worklib.rad_srt, by: [:Distributor_Key, :Retailer_Ext_Key, :Item_Number, :Date_of_Data], split_size: 100000
end

=begin
time = Benchmark.realtime do
  Datastep.create worklib.test do |ds|
    Variables.define ds do |v|
      v.import worklib.rad
    end

    Datastep.read worklib.rad do |in_ds|
      ds.read_row_from in_ds
      ds.write_row
    end
  end
end
=end
puts "Time: #{time}"

#Dataview.view worklib.rad
#Dataview.view worklib.rad_srt







