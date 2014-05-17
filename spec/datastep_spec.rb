require 'remi_spec'

describe Datastep do
  before do
    # Create a dummy dataset that we will validate was created properly in the specs
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    Datastep.create @work.have do |have|
      Variables.define have do |v|
        v.create :rownum, :type => "number"
        v.create :retailer_key
        v.create :physical_cases, :type => "number"
      end

      for i in 1..10
        have[:rownum] = i
        have[:retailer_key] = "0123456789"
        have[:physical_cases] = 15

        have.write_row
      end
    end
  end


  describe "the dummy dataset created" do
    it "should have the right variables" do
      vars = nil
      Datastep.read @work.have do |ds|
        vars = ds.vars.keys
        break
      end
      vars.should =~ [:rownum,:retailer_key,:physical_cases]
    end

    it "should enable easy read of the variables", :future => true do
      @work.have.vars.keys.should =~ [:rownum,:retailer_key,:physical_cases]
    end

    describe "the data that should be present in the dataset" do
      before do
        @count_have_rows = 0
        @sum_physical_cases = 0
        @last_retailer_key = ""
        @slice_rownum = []
        @slice_N = []

        Datastep.read @work.have do |have|
          @count_have_rows += 1
          @sum_physical_cases += have[:physical_cases]
          @last_retailer_key = have[:retailer_key]
          @slice_rownum << have[:rownum]
          @slice_N << have._N_
        end
      end
      
      it "should have the right number of rows" do
        @count_have_rows.should eq 10
      end

      it "should have assigned values to the dataset variables" do
        @last_retailer_key.should eq "0123456789"
      end
      
      it "should have the right aggregate sum" do
        @sum_physical_cases.should eq 150
      end

      it "should have set the row counter variable" do
        @slice_rownum.should eq @slice_N
      end
    end
  end


  describe "creating a derived dataset" do
    before do
      Datastep.create @work.want do |want|
        Variables.define want do |v|
          v.create :alt_key
          v.import @work.have
          v.create :russell
        end

        # Define an instance method so we don't have to duplicate this code
        # in both the dummy row and the read row
        def want.default_assignments
          self[:alt_key] = "TD-#{self[:retailer_key]}"
          self[:rownum] = self._N_
        end

        # Add a dummy row at the beginning just to make it interesting
        want[:retailer_key] = "0000000000"
        want[:physical_cases] = 0
        want[:russell] = "RUSSELL!!"
        want.default_assignments

        want.write_row

        Datastep.read @work.have do |have|
          want.read_row_from have, drop: [:rownum]
          want.default_assignments
          want.write_row
        end
      end
    end

    it "should have the added variables in the right order" do
      vars = nil
      Datastep.read @work.want do |ds|
        vars = ds.vars.keys
        break
      end
      vars.should eq [:alt_key,:rownum,:retailer_key,:physical_cases,:russell]
    end

    it "should enable easy read of the added variables", :future => true do
      @work.want.vars.keys.should eq [:alt_key,:rownum,:retailer_key,:physical_cases,:russell]
    end

    describe "the data that should be in the derived dataset" do
      before do
        @count_want_rows = 0
        @sum_physical_cases = 0
        @last_retailer_key = ""
        @first_alt_key = ""
        Datastep.read @work.want do |want|
          @count_want_rows += 1
          @sum_physical_cases += want[:physical_cases]
          @last_retailer_key = want[:retailer_key]
          @first_alt_key = want[:alt_key] if want._N_ == 1
        end
      end

      it "should have the right number of rows" do
        @count_want_rows.should eq 11
      end

      it "should have the right aggregate sum" do
        @sum_physical_cases.should eq 150
      end

      it "should have assigned values to the dataset variables" do
        @last_retailer_key.should eq "0123456789"
      end
      
      it "should contain the dummy header row" do
        @first_alt_key.should eq "TD-0000000000"
      end
    end
  end
end

