require "test_remi"

class Test_bygroup < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    mydata = [
              ["A",1,"row 1"],
              ["A",1,"row 2"],
              ["A",2,"row 3"],
              ["A",2,"row 4"],
              ["B",2,"row 5"],
              ["B",3,"row 6"],
              ["B",3,"row 7"],
              ["C",4,"row 8"],
              ["D",2,"row 9"],
              ["D",3,"row 10"]
             ]
             
    Datastep.create @work.mydata do |ds|
      Variables.define ds do |v|
        v.create :grp1
        v.create :grp2, :type => "number"
        v.create :data
      end

      mydata.each do |row|
        ds.row = row
        ds.write_row
      end
    end
  end

  def teardown
    # Add a delete data function
  end

  def test_bygroup

    Datastep.create @work.with_first_last do |ds|
      Variables.define ds do |v|
        v.import @work.mydata
        v.create :first_grp1
        v.create :last_grp1
      end

      Datastep.read @work.mydata, by: [:grp1] do |mydata|
        ds.read_row_from mydata
        ds[:first_grp1] = mydata.first(:grp1)
        ds[:last_grp1] = mydata.last(:grp1)

        ds.write_row
      end
      
    end

    Dataview.view @work.with_first_last

  end
end


