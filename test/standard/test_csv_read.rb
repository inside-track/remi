require "test_remi"

class Test_csv_read < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
    @csv_file_full_path = File.join(File.dirname(__FILE__),"resources/test_file.csv")
  end

  def teardown
  end

  def assert_physical_cases
    physical_cases = 0
    Datastep.read @work.from_csv do |ds|
      physical_cases += ds[:RAD__Physical_Cases].to_f
    end

    assert_equal 10.0, physical_cases, "Expected physical_cases = 10.0, found #{physical_cases}"    
  end

  def test_csv_std_read_custom_headers
    Datastep.create @work.from_csv do |ds|
      Variables.define ds do |v|
        v.create :RAD__Fact_Key, :type => "string", :csv_col => 0
        v.create :Distributor__Dim_Key, :type => "string", :csv_col => 1
        v.create :RAD__Physical_Cases, :type => "number", :csv_col => 7
      end

      CSV.open(@csv_file_full_path, "r") do |rows|
        rows.each do |row|
          if $. == 1 then next end # skip header

          ds[:RAD__Fact_Key] = row[ds.vars[:RAD__Fact_Key][:csv_col]]
          ds[:Distributor__Dim_Key] = row[ds.vars[:Distributor__Dim_Key][:csv_col]]
          ds[:RAD__Physical_Cases] = row[ds.vars[:RAD__Physical_Cases][:csv_col]]

          ds.write_row
        end
      end
    end
    
    assert_physical_cases

  end


  def test_csv_helper_read_custom_headers

    Datastep.create @work.from_csv do |ds|
      Variables.define ds do |v|
        v.create :RAD__Fact_Key, :type => "string", :csv_col => 0
        v.create :Distributor__Dim_Key, :type => "string", :csv_col => 1
        v.create :RAD__Physical_Cases, :type => "number", :csv_col => 7
      end

      CSV.datastep(@csv_file_full_path, "r") do |row|
        ds.read_row_from_csv(row)
        ds.write_row
      end
    end
    
    assert_physical_cases

  end

=begin
  def test_csv_std_read_trust_header

    Datastep.create @work.from_csv do |ds|
      CSV.open(@csv_file_full_path, "r", 
               { :headers => true, 
                 :return_headers => true 
               }) do |rows|

        if rows.header_row?
          rows.readline

          ds.define_variables do
            rows.headers.each do |header|
              var header.to_sym, :type => "string"
            end
          end

        end
          
        rows.each do |row|
          puts row.inspect

          row.each do |key,value|
            ds[key.to_sym] = value
          end

          ds.write_row
        end
      end
    end

    assert_physical_cases
  end


  def test_csv_helper_read_trust_header

    Datastep.create @work.from_csv do |ds|
      CSV.open(@csv_file_full_path, "r", 
               { :headers => true, 
                 :return_headers => true 
               }) do |rows|

        puts rows.inspect

        puts "HEADER_ROW: #{rows.header_row?}"
        if rows.header_row?
          rows.readline
          puts "HEADERS: #{rows.headers}"

          csv_headers = []
          ds.define_variables do
            rows.headers.each do |header|
              var header.to_sym, :type => "string"
              csv_headers << header.to_sym
            end
          end
          puts "csv_headers: #{csv_headers}"

        end
          
        rows.each do |row|
          puts row.inspect

          row.each do |key,value|
            puts "writing key=#{key}, value=#{value}"
            ds[key.to_sym] = value
          end

          ds.write_row
        end
      end
    end

    assert_physical_cases
  end
=end
end
