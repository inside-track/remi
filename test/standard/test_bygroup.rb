require "test_remi"

class Test_bygroup < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    @expected = [
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
             
    Datastep.create @work.mydata do |mydata|
      Variables.define mydata do |v|
        v.create :grp1
        v.create :grp2, :type => "number"
        v.create :data
      end

      @expected.each do |row|
        mydata.row = row[0..2]
        mydata.write_row
      end
    end
  end

  def teardown
    # Add a delete data function
  end

  def test_bygroup
    Datastep.create @work.test_by_group do |ds|
      Variables.define ds do |v|
        v.import @work.mydata
        v.create :first_grp1
        v.create :first_grp2
        v.create :last_grp1
        v.create :last_grp2
      end

      Datastep.read @work.mydata, by: [:grp1,:grp2] do |mydata|
        ds.read_row_from mydata
        ds[:first_grp1] = mydata.first(:grp1)
        ds[:last_grp1] = mydata.last(:grp1)
        ds[:first_grp2] = mydata.first(:grp2)
        ds[:last_grp2] = mydata.last(:grp2)

        ds.write_row
      end
    end

    actual = []
    Datastep.read @work.test_by_group do |ds|
      actual << ds.row
    end

    assert_equal actual, @expected, "Expected first/last flags not found"
  end
end


