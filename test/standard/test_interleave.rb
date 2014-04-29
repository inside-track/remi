require "test_remi"

class Test_interleave < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    data_A = [
              ["A",1,"in A row 1"],
              ["A",1,"in A row 2"],
              ["B",2,"in A row 3"],
              ["B",2,"in A row 4"],
              ["C",4,"in A row 5"],
              ["C",4,"in A row 6"],
              ["C",4,"in A row 7"],
              ["C",5,"in A row 8"]
             ]

    data_B = [
              ["B",1,"in B row 1","Beta 1"],
              ["B",2,"in B row 2","Beta 2"],
              ["B",2,"in B row 3","Beta 2"],
              ["B",5,"in B row 4","Beta 5"],
              ["B",6,"in B row 5","Beta 6"]
             ]
             
    Datastep.create @work.data_A, @work.data_B  do |dsA,dsB|
      Variables.define dsA, dsB do |v|
        v.create :grp1
        v.create :grp2, :type => "number"
        v.create :shared_data
      end

      Variables.define dsB do |v|
        v.create :B_data
      end

      data_A.each do |row|
        dsA.row = row
        dsA.write_row
      end

      data_B.each do |row|
        dsB.row = row
        dsB.write_row
      end
    end
  end

  def teardown
    # Add a delete data function
  end

  def test_interleave
    Datastep.create @work.data_C do |ds|
      Variables.define ds do |v|
        v.import @work.data_A
        v.import @work.data_B
        v.create :in_ds_name
      end

      Datastep.interleave @work.data_A, @work.data_B, by: [:grp1,:grp2] do |dsi|
        # dsi could be an interleave object that contains whichever
        # dataset is up next but also includes other information
        # like the name of which dataset it's in
#        puts "Reading interleaved row from #{dsi.dataset_name}"
        ds.read_row_from dsi
        ds[:in_ds_name] = dsi.name
        ds.write_row
      end
    end

#    Dataview.view @work.data_A
#    Dataview.view @work.data_B
    Dataview.view @work.data_C
  end
end


