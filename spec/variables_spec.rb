require 'remi_spec'

describe Variables do

  before do
    @work = Datalib.new :directory => { :dirname => RemiConfig.work_dirname }

    def define_test_variables(*args)
      Variables.define *args do |v|
        v.create :rownum, :type => "number"
        v.create :retailer_key, :meta1 => "one", :meta2 => "two", :meta3 => "three"
        v.create :retailer_name
        v.create :physical_cases, :type => "number"
      end
    end
  end


  describe "single dataset variable definitions" do
    before do
      @ds = @work.ds
      define_test_variables(@ds)
    end

    it "should create variables" do
      @ds.vars.keys.should =~ [:rownum,:retailer_key,:retailer_name,:physical_cases]
    end

    it "should allow variables to be assigned" do
      @ds[:rownum] = 53
      @ds[:rownum].should eq 53
    end

    it "should fail when assigning undefined variables" do
      expect { @ds[:undefined] = 44 }.to raise_error(NameError)
    end
  end


  describe "multiple dataset variable definitions" do
    before do
      @ds1 = @work.ds1
      @ds2 = @work.ds2
      define_test_variables(@ds1,@ds2)

      Variables.define @ds1 do |v|
        v.create :in_ds1
      end

      Variables.define @ds2 do |v|
        v.create :in_ds2
      end

      @ds1[:rownum] = 0
      @ds1[:in_ds1] = true
      @ds2[:in_ds2] = true
    end

    it "should share common variables" do
      ds1_common_keys = @ds1.vars.keys - [:in_ds1]
      ds2_common_keys = @ds2.vars.keys - [:in_ds2]
      ds1_common_keys.should eq ds2_common_keys
    end
  end


  describe "assigning variables from another dataset" do
    before do
      @ds1 = @work.ds1
      @ds2 = @work.ds2
      define_test_variables(@ds1)
    end

    it "should import all variables" do
      Variables.define @ds2 do |v|
        v.import @ds1
      end
      @ds2.vars.keys.should =~ [:rownum,:retailer_key,:retailer_name,:physical_cases]
    end

    it "should import only specified variables" do
      Variables.define @ds2 do |v|
        v.import @ds1, :keep => [:retailer_key,:physical_cases]
      end
      @ds2.vars.keys.should =~ [:retailer_key,:physical_cases]
    end

    it "should not import only specified variables" do
      Variables.define @ds2 do |v|
        v.import @ds1, :drop => [:retailer_key,:physical_cases]
      end
      @ds2.vars.keys.should =~ [:rownum,:retailer_name]
    end
  end


  describe "modifying variable metadata" do
    before do
      @ds1 = @work.ds1
      define_test_variables(@ds1)
    end

    describe "altering existing metadata" do
      before do
        Variables.define @ds1 do |v|
          v.modify_meta :retailer_key, :meta2 => "beta"
        end
      end

      it "should alter existing metadata" do
        @ds1.vars[:retailer_key][:meta2].should eq "beta"
      end

      it "should not alter non-specified metadata" do
        @ds1.vars[:retailer_key][:meta1].should eq "one"
      end
    end

    it "should append new metadata" do
      Variables.define @ds1 do |v|
        v.modify_meta :retailer_key, :md5_sum => true
      end
      @ds1.vars[:retailer_key].keys.should =~ [:type,:meta1,:meta2,:meta3,:md5_sum]
    end

    it "should clear all metadata with a subsequent create statement" do
      Variables.define @ds1 do |v|
        v.create :retailer_key, :newmeta => "george"
      end
      @ds1.vars[:retailer_key].keys.should =~ [:type,:newmeta]
    end

    it "should not drop manditory metadata (:type)" do
      Variables.define @ds1 do |v|
        v.drop_meta :retailer_key, :meta2, :type
      end
      @ds1.vars[:retailer_key].keys.should include :type
    end

    it "should keep manditory metadata even if not specified" do
      Variables.define @ds1 do |v|
        v.keep_meta :retailer_key, :meta4
      end
      @ds1.vars[:retailer_key].keys.should include :type
    end
  end
end
