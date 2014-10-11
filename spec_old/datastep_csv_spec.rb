require 'remi_spec'

describe "Datastep CSV Reader" do
  before do
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
    @csv_file_full_path = File.join(File.dirname(__FILE__),"resources/test_file.csv")
  end

  def test_physical_cases(ds)
    physical_cases = 0
    Datastep.read ds do |ds|
      physical_cases += ds[:RAD__Physical_Cases].to_f
    end
    physical_cases
  end

  describe "reading a csv without the helper using custom headers" do
    before do
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
    end

    it "should have read all of the data" do
      test_physical_cases(@work.from_csv).should eq 10.0
    end
  end


  describe "reading a csv with the helper using custom headers" do
    before do
      Datastep.create @work.from_csv do |ds|
        Variables.define ds do |v|
          v.create :RAD__Fact_Key, :type => "string", :csv_col => 0
          v.create :Distributor__Dim_Key, :type => "string", :csv_col => 1
          v.create :RAD__Physical_Cases, :type => "number", :csv_col => 7
        end

        CSV.datastep @csv_file_full_path do |row|
          ds.read_row_from_csv(row)
          ds.write_row
        end
      end
    end

    it "should have read all of the data" do
      test_physical_cases(@work.from_csv).should eq 10.0
    end
  end


  describe "reading a csv without the helper and trusting headers" do
    before do
      Datastep.create @work.from_csv do |ds|
        CSV.open(@csv_file_full_path, "r", 
                 { :headers => true, 
                   :return_headers => true 
                 }) do |rows|

          if rows.header_row?
            rows.readline

            Variables.define ds do |v|
              rows.headers.each do |header|
                v.create header.to_sym
              end
            end
          end

          rows.each do |row|
            row.each do |key,value|
              ds[key.to_sym] = value
            end

            ds.write_row
          end
        end
      end
    end

    it "should have read all of the data" do
      test_physical_cases(@work.from_csv).should eq 10.0
    end
  end


  describe "reading a csv with the helper and trusting headers" do
    before do
      Datastep.create @work.from_csv do |ds|
        CSV.datastep @csv_file_full_path, header_to_vars: ds do |row|
          ds.read_row_from_csv(row)
          ds.write_row
        end
      end
    end

    it "should have read all of the data" do
      test_physical_cases(@work.from_csv).should eq 10.0
    end
  end
end

