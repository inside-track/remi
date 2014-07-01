require 'remi_spec'

describe Variable do

  describe "A variable is an object that has a value and metadata" do

    context "which can be created in one line" do
      subject(:id) { Variable.new :some_meta => "That's so meta" }

      it { should have_key(:some_meta) }

      it "should define the mandatory type key" do
        subject.should have_key(:type)
      end

      context "using an array accessor to return metadata" do
        specify { expect(subject[:some_meta]).to eq "That's so meta" }
      end

      context "using an array accessor to modify metadata" do
        before { id[:some_meta] = "Metamodify" }
        specify { expect(id[:some_meta]).to eq "Metamodify" }
      end
    end

    context "and can be defined in a block" do
      let(:id) do
        Variable.define do
          meta :type      => "string"
          meta :length    => 18
          meta :some_meta => "More meta than you"
        end
      end

      specify { expect(id).to have_key(:length) }

      context "which is useful for importing variable metadata from other variables" do
        let(:id_derived) do
          id_origin = id # Don't understand why id not in scope of block below

          Variable.define do
            like id_origin
            meta :alt_meta => "Way, way meta"
          end
        end

        specify { expect(id_derived).to have_key(:some_meta) }
        specify { expect(id_derived).to have_key(:alt_meta) }
      end
    end
  end

  describe "Modifying metadata" do
    subject(:id) do
      Variable.define do
        meta :type      => "string"
        meta :length    => 18
        meta :meta_keep => "More meta than you"
        meta :meta_drop => "Way more meta than you"
      end
    end

    shared_examples "surviving metadata" do
      specify { expect(subject).to have_keys(:type, :length, :meta_keep) }
      specify { expect(subject).not_to have_key(:meta_drop) }
    end


    context "can be non-destructively dropped" do
      subject(:id_derived) { id.drop_meta :meta_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively dropped" do
      before { id.drop_meta! :meta_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be non-destructively kept" do
      subject(:id_derived) { id.keep_meta :length, :meta_keep }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively kept" do
      before { id.keep_meta! :length, :meta_keep }
      it_behaves_like "surviving metadata"
    end
  end
end


=begin SOME OLD WORLD STUFF

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

    shared_examples_for "assigning variables from another dataset" do
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

    describe "with a transient datalib" do
      before do
        tmplib = Datalib.new :transient => {}
        @ds1 = tmplib.ds1
        @ds2 = tmplib.ds2
        define_test_variables(@ds1)
      end

      it_behaves_like "assigning variables from another dataset"
    end

    # SO, the above works, but I don't like that it has to use the tmplib library
    describe "with a standard datalib", :future => true do
      before do
        @ds1 = @work.ds1
        @ds2 = @work.ds2
        define_test_variables(@ds1)
      end

      it_behaves_like "assigning variables from another dataset"
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
=end
