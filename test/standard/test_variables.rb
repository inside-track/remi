require "test_remi"

class Test_variables < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
  end

  def teardown
    # Add a delete data function
  end

  def same_vars?(expected,result)
    test = (expected - result) == (result - expected)
    assert test, "Unexpected variables: FOUND: #{result}, EXPECTED: #{expected}"
  end

  def same_meta?(expected,result)
    test = (expected - result) == (result - expected)
    assert test, "Unexpected metadata: FOUND: #{result}, EXPECTED: #{expected}"
  end

  def test_variables_define
    ds = @work.ds

    Variables.define ds do |v|
      v.create :rownum, :type => "number"
      v.create :retailer_key
      v.create :retailer_name
      v.create :physical_cases, :type => "number"
    end
    same_vars?([:rownum,:retailer_key,:retailer_name,:physical_cases],ds.vars.keys)

    ds[:rownum] = 0
    assert_equal 0, ds[:rownum], "Unable to assign variable"

    assert_raise NameError do
      ds[:x] = "x"
    end

    assert_raise NameError do
      puts ds[:x]
    end
  end


  def test_variables_define_multiple_datasets
    ds1 = @work.ds1
    ds2 = @work.ds2

    Variables.define ds1,ds2 do |v|
      v.create :rownum, :type => "number"
      v.create :retailer_key
      v.create :retailer_name
      v.create :physical_cases, :type => "number"
    end
    same_vars?(ds1.vars.keys,ds2.vars.keys)

    Variables.define ds1 do |v|
      v.create :in_ds1
    end

    Variables.define ds2 do |v|
      v.create :in_ds2
    end

    ds1[:rownum] = 0
    ds1[:in_ds1] = true
    ds2[:in_ds2] = true

    assert_equal 0, ds1[:rownum], "Unable to assign variable"
    assert_equal true, ds1[:in_ds1], "Unable to assign variable"
    assert_equal true, ds2[:in_ds2], "Unable to assign variable"
  end


  def test_assign_variables_from_other_dataset
    ds1 = @work.ds1
    ds2 = @work.ds2
    ds3 = @work.ds3
    ds4 = @work.ds4

    Datastep.create ds1 do |ds1|
      Variables.define ds1 do |v|
        v.create :rownum, :type => "number"
        v.create :retailer_key
        v.create :retailer_name
        v.create :physical_cases, :type => "number"
      end
    end

    Variables.define ds2 do |v|
      v.import ds1
    end
    same_vars?([:rownum,:retailer_key,:retailer_name,:physical_cases],ds2.vars.keys)

    Variables.define ds3 do |v|
      v.import ds1, :keep => [:retailer_key,:physical_cases]
    end
    same_vars?([:retailer_key,:physical_cases],ds3.vars.keys)

    Variables.define ds4 do |v|
      v.import ds1, :drop => [:rownum,:retailer_key]
    end
    same_vars?([:retailer_name,:physical_cases],ds4.vars.keys)
  end


  def test_modify_variables
    ds1 = @work.ds1
    ds2 = @work.ds2

    Variables.define ds1 do |v|
      v.create :rownum, :type => "number"
      v.create :retailer_key, :meta1 => "one", :meta2 => "two", :meta3 => "three", :meta4 => "four"
      v.create :retailer_name
      v.create :physical_cases, :type => "number"
    end

    Variables.define ds1 do |v|
      v.modify_meta :rownum, :md5_sum => true
    end
    same_meta?([:type,:md5_sum],ds1.vars[:rownum].keys)

    # Metadata should be overwritten with second create statement
    Variables.define ds1 do |v|
      v.create :rownum
    end
    same_meta?([:type],ds1.vars[:rownum].keys)
    assert_equal "string", ds1.vars[:rownum][:type], "Create did not overwrite variable metadata"

    # Note that you cannot drop manditory metadata (:type)
    Variables.define ds1 do |v|
      v.drop_meta :retailer_key, :meta2, :type
    end
    same_meta?([:type,:meta1,:meta3,:meta4],ds1.vars[:retailer_key].keys)

    # Note that keep does not apply to manditory metadata (:type)
    Variables.define ds1 do |v|
      v.keep_meta :retailer_key, :meta4
    end
    same_meta?([:type,:meta4],ds1.vars[:retailer_key].keys)
  end
end


