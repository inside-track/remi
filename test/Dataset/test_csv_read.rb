require "test_remi"

class Test_csv_read < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
    work = @work
  end

  def teardown
  end

  def test_csv_read
    work = @work

    csv_file_full_path = File.join(File.dirname(__FILE__),"test_file.csv")

    Datastep.create work.from_csv do |from_csv|
      from_csv.define_variables do
        var :RAD__Fact_Key, :type => "string"
        var :Distributor__Dim_Key, :type => "string"
        var :RAD__Physical_Cases, :type => "number"
      end


#    CSV.open(csv_file_full_path, "r", { :headers => true }) do |rows|
      CSV.open(csv_file_full_path, "r") do |rows|
        rows.each do |row|
#          puts "row: #{row.inspect}"
          from_csv[:RAD__Fact_Key] = row[0]
          from_csv[:Distributor__Dim_Key] = row[1]
          from_csv[:RAD__Physical_Cases] = row[7]

          from_csv.output
        end
      end
    end

    Dataview.view work.from_csv
    
  end
end

=begin
def serialize_json(in_filename,out_filename,columns,debug=false)

  file = File.open(out_filename,"w")
  gz = Zlib::GzipWriter.new(file)


  sum = 0
#  CSV.open(in_filename, "r", { :headers => true } ) do |rows|
  CSV.open(in_filename, "r") do |rows|


    rows.each do |row|
      puts "row: #{row.inspect}" if debug
      puts "row is class #{row.class}" if debug
      puts row.to_json if debug
      gz.puts row.to_json
      sum = sum + row[columns[:physical_cases]].to_f
      line_number = $.
      puts "#{line_number}" if line_number % 50000 == 0
    end

  end
  puts "Physical_Cases: sum = #{sum}"

  gz.close

end
=end
