require "test_remi"

class Test_csv_read < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
    work = @work
  end

  def teardown
  end

  def test_csv_read_custom_headers
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
          if $. == 1 then next end # skip header

          from_csv[:RAD__Fact_Key] = row[0]
          from_csv[:Distributor__Dim_Key] = row[1]
          from_csv[:RAD__Physical_Cases] = row[7]

          from_csv.output
        end
      end
    end

#    Dataview.view work.from_csv
    
  end

# YEAH, THIS NEEDS TO BE SIMPLER!!!!
  
  def test_csv_read_trust_header
    work = @work
    csv_file_full_path = File.join(File.dirname(__FILE__),"test_file.csv")


    count_csv_rows = 0
    Datastep.create work.from_csv do |from_csv|

      puts "-----------"
      CSV.open(csv_file_full_path, "r", { :headers => true, :return_headers => true }) do |rows|
        puts rows.inspect

        puts "HEADER_ROW: #{rows.header_row?}"
        if rows.header_row?
          rows.readline
          puts "HEADERS: #{rows.headers}"

          csv_headers = []
          from_csv.define_variables do
            rows.headers.each do |header|
              var header.to_sym, :type => "string"
              csv_headers << header.to_sym
            end
          end
          puts "csv_headers: #{csv_headers}"

        end
          
        rows.each do |row|

          count_csv_rows += 1
          puts row.inspect

          row.each do |key,value|
            puts "writing key=#{key}, value=#{value}"
            from_csv[key.to_sym] = value
          end

            from_csv.output

        end


=begin
        from_csv.define_variables do
          var :RAD__Fact_Key, :type => "string"
          var :Distributor__Dim_Key, :type => "string"
          var :RAD__Physical_Cases, :type => "number"
        end

        rows.each do |row|
          if $. == 1 then next end # skip header

          from_csv[:RAD__Fact_Key] = row[0]
          from_csv[:Distributor__Dim_Key] = row[1]
          from_csv[:RAD__Physical_Cases] = row[7]

          from_csv.output
        end
=end
      end
    end

    assert_equal 10, count_csv_rows, "Expected 10 rows(+1 header), found #{count_csv_rows}"
    Dataview.view work.from_csv
    
  end
end
