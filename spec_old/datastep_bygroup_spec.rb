require 'remi_spec'

describe "Datastep by groups" do
  before do
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
  end


  describe "single variable by groups" do
    def test_by_groups(data_array, input_columns_range)
      test_data = data_array.map { |row| row[input_columns_range] }

      Datastep.create @work.have do |ds|
        Variables.define ds do |v|
          v.create :grp1
          v.create :data
        end

        test_data.each do |row|
          ds.row = row
          ds.write_row
        end
      end

      result_data = []
      Datastep.read @work.have, by: :grp1 do |ds|
        result_data << [ds.row, ds.first(:grp1), ds.last(:grp1)].flatten
      end
      result_data
    end

    it "should report first/last correctly in a complex example" do
      test_array = [
                    ["A","row 1",true,false],
                    ["A","row 2",false,true],
                    ["B","row 3",true,false],
                    ["B","row 4",false,false],
                    ["B","row 5",false,false],
                    ["B","row 6",false,true],
                    ["C","row 7",true,false],
                    ["C","row 8",false,true]
                   ]
      test_by_groups(test_array, 0..1).should eq test_array
    end

    it "should fail if not defined properly" do
      test_array = [
                    ["A","row 1",true,false],
                    ["A","row 2",false,true],
                    ["A","row 3",true,false],
                    ["A","row 4",false,false],
                   ]
      test_by_groups(test_array, 0..1).should_not eq test_array
    end

    it "should be able to handle single-record groups at the beginning/end" do
      test_array = [
                    ["A","row 1",true,true],
                    ["B","row 2",true,false],
                    ["B","row 3",false,false],
                    ["B","row 4",false,false],
                    ["B","row 5",false,false],
                    ["B","row 6",false,true],
                    ["C","row 7",true,true]
                   ]
      test_by_groups(test_array, 0..1).should eq test_array
    end

    it "should even work with unsorted data" do
      test_array = [
                    ["A","row 1",true,false],
                    ["A","row 2",false,true],
                    ["C","row 3",true,false],
                    ["C","row 4",false,true],
                    ["B","row 5",true,false],
                    ["B","row 6",false,false],
                    ["B","row 7",false,false],
                    ["B","row 8",false,true]
                   ]
      test_by_groups(test_array, 0..1).should eq test_array
    end

    it "should work with nil and empty values" do
      test_array = [
                    ["A","row 1",true,false],
                    ["A","row 2",false,true],
                    [nil,"row 3",true,false],
                    [nil,"row 4",false,true],
                    ["","row 5",true,false],
                    ["","row 6",false,false],
                    ["","row 7",false,false],
                    ["","row 8",false,true]
                   ]
      test_by_groups(test_array, 0..1).should eq test_array
    end
  end


  describe "mutliple variable by groups" do
    def test_by_groups(data_array, input_columns_range)
      test_data = data_array.map { |row| row[input_columns_range] }

      Datastep.create @work.have do |ds|
        Variables.define ds do |v|
          v.create :grp1
          v.create :grp2
          v.create :data
        end

        test_data.each do |row|
          ds.row = row
          ds.write_row
        end
      end

      result_data = []
      Datastep.read @work.have, by: [:grp1, :grp2] do |ds|
        result_data << [ds.row, ds.first(:grp1), ds.first(:grp2), 
                        ds.last(:grp1), ds.last(:grp2)].flatten
      end
      result_data
    end

    it "should report first/last correctly in a complex example" do
      test_array = [
                    ["A",1,"row 1",true,true,false,false],
                    ["A",1,"row 2",false,false,false,true],
                    ["A",2,"row 3",false,true,false,false],
                    ["A",2,"row 4",false,false,true,true],
                    ["B",2,"row 5",true,true,false,true],
                    ["B",3,"row 6",false,true,false,false],
                    ["B",3,"row 7",false,false,true,true],
                    ["C",3,"row 8",true,true,true,true],
                    ["D",2,"row 9",true,true,false,true],
                    ["D",3,"row 10",false,true,true,true]
                   ]
      test_by_groups(test_array, 0..2).should eq test_array
    end
  end
end
