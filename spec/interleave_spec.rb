require "remi_spec"

describe "Interleaving datasets" do
  before do
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    data_1 = [
              ["A",1,"ds1","row 1"],
              ["B",2,"ds1","row 2"],
              ["B",5,"ds1","row 3"],
              ["E",1,"ds1","row 4"],
              ["E",2,"ds1","row 5"],
              ["E",3,"ds1","row 6"],
              ["E",4,"ds1","row 7"]
             ]

    data_2 = [
              ["C",1,"ds2","row 1","Deux 1"],
              ["C",2,"ds2","row 2","Deux 1"],
              ["F",1,"ds2","row 3","Deux 2"],
              ["F",2,"ds2","row 4","Deux 2"],
              ["F",3,"ds2","row 5","Deux 2"]
             ]
    data_3 = [
              ["B",1,"ds3","row 1"],
              ["B",2,"ds3","row 2"],
              ["B",3,"ds3","row 3"],
              ["B",6,"ds3","row 4"],
              ["D",1,"ds3","row 5"],
              ["D",2,"ds3","row 6"]
             ]

    @total_rows = data_1.count + data_2.count + data_3.count

    Datastep.create @work.ds1, @work.ds2, @work.ds3  do |ds1,ds2,ds3|
      Variables.define ds1, ds2, ds3 do |v|
        v.create :grp1
        v.create :grp2, :type => "number"
        v.create :in_txt
        v.create :row_number_txt
      end

      Variables.define ds2 do |v|
        v.create :extra_data
      end

      [[data_1, ds1], [data_2, ds2], [data_3, ds3]].each do |pair|
        pair_array = pair[0]
        pair_ds = pair[1]

        pair_array.each do |row|
          pair_ds.row = row
          pair_ds.write_row
        end
      end
    end
  end


  describe "with a two element by group" do
    before do
      Datastep.create @work.ds_interleaved do |ds|
        Variables.define ds do |v|
          v.import @work.ds1
          v.import @work.ds2
          v.import @work.ds3
          v.create :in_ds_name
        end

        Datastep.interleave @work.ds1, @work.ds2, @work.ds3, by: [:grp1,:grp2] do |dsi|
          ds.read_row_from dsi
          ds[:in_ds_name] = dsi.name
          ds.write_row
        end
      end
    end


    it "should interleave groups ABE,CF,BD like ABCDEF" do
      ordered_grp1 = []
      Datastep.read @work.ds_interleaved do |ds|
        ordered_grp1 << ds[:grp1] unless ordered_grp1[-1] == ds[:grp1]
      end

      ordered_grp1.join.should eq "ABCDEF"
    end

    it "should set the correct dataset name" do
      Datastep.read @work.ds_interleaved do |ds|
        ds[:in_ds_name].should eq ds[:in_txt]
      end
    end

    it "should show nulls for extra data in ds2, except when it came from ds2" do
      Datastep.read @work.ds_interleaved do |ds|
        ds[:extra_data].should eq "" unless ds[:in_txt] = "ds2"
        ds[:extra_data].should_not eq "" if ds[:in_txt] = "ds2"
      end
    end

    it "should interleave the subgroups of B" do
      ordered_grp2 = []
      Datastep.read @work.ds_interleaved do |ds|
        if ds[:grp1] == "B"
          ordered_grp2 << ds[:grp2] unless ordered_grp2[-1] == ds[:grp2]
        end
      end
      
      ordered_grp2.join.should eq "12356"
    end

    it "should have the expected number rows" do
      count_rows = 0
      Datastep.read @work.ds_interleaved do |ds|
        count_rows += 1
      end
      
      count_rows.should eq @total_rows
    end

    # This test is a kind of catch-all that should fail if I missed a test case above
    it "should reproduce the expected full output" do
      data_expected = [
                       ["A",1,"ds1","row 1",nil,"ds1"],
                       ["B",1,"ds3","row 1",nil,"ds3"],
                       ["B",2,"ds3","row 2",nil,"ds3"],
                       ["B",2,"ds1","row 2",nil,"ds1"],
                       ["B",3,"ds3","row 3",nil,"ds3"],
                       ["B",5,"ds1","row 3",nil,"ds1"],
                       ["B",6,"ds3","row 4",nil,"ds3"],
                       ["C",1,"ds2","row 1","Deux 1","ds2"],
                       ["C",2,"ds2","row 2","Deux 1","ds2"],
                       ["D",1,"ds3","row 5",nil,"ds3"],
                       ["D",2,"ds3","row 6",nil,"ds3"],
                       ["E",1,"ds1","row 4",nil,"ds1"],
                       ["E",2,"ds1","row 5",nil,"ds1"],
                       ["E",3,"ds1","row 6",nil,"ds1"],
                       ["E",4,"ds1","row 7",nil,"ds1"],
                       ["F",1,"ds2","row 3","Deux 2","ds2"],
                       ["F",2,"ds2","row 4","Deux 2","ds2"],
                       ["F",3,"ds2","row 5","Deux 2","ds2"],
                      ]
      data_actual = []
      Datastep.read @work.ds_interleaved do |ds|
        data_actual << ds.row
      end

      data_actual.should eq data_expected
    end

    it "should be visually accurate", :manual => true do
      Dataview.view @work.ds1
      Dataview.view @work.ds2
      Dataview.view @work.ds3
      Dataview.view @work.ds_interleaved
    end
  end


  describe "without by group (aka stacking)" do
    it "should stack datasets 1,2,3 like 123" do
      ordered_ds = []
      Datastep.create @work.ds_interleaved do |ds|
        Variables.define ds do |v|
          v.import @work.ds1
          v.import @work.ds2
          v.import @work.ds3
          v.create :in_ds_name
        end

        Datastep.interleave @work.ds1, @work.ds2, @work.ds3, by: []  do |dsi|
          ds.read_row_from dsi
          ds[:in_ds_name] = dsi.name
          ordered_ds << ds[:in_ds_name] unless ordered_ds[-1] == ds[:in_ds_name]
          ds.write_row
        end
      end

      ordered_ds.join.should eq "ds1ds2ds3"
    end

    it "should stack datasets 2,3,2,1 like 2321" do
      ordered_ds = []
      Datastep.create @work.ds_interleaved do |ds|
        Variables.define ds do |v|
          v.import @work.ds1
          v.import @work.ds2
          v.import @work.ds3
          v.create :in_ds_name
        end

        Datastep.interleave @work.ds2, @work.ds3, @work.ds2, @work.ds1, by: []  do |dsi|
          ds.read_row_from dsi
          ds[:in_ds_name] = dsi.name
          ordered_ds << ds[:in_ds_name] unless ordered_ds[-1] == ds[:in_ds_name]
          ds.write_row
        end
      end

      ordered_ds.join.should eq "ds2ds3ds2ds1"
    end
  end
end
