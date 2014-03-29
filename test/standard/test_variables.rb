require "test_remi"

class Test_variables < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
  end

  def teardown
    # Add a delete data function
  end


  def test_variables_define
    ds = @work.ds

    Variables.define ds do |v|
      v.create :rownum, :type => "number"
      v.create :retailer_key
      v.create :retailer_name
      v.create :physical_cases, :type => "number"
    end

    ds[:rownum] = 0
    assert_equal 0, ds[:rownum], "Unable to assign variable"

    assert_raise NameError do
      ds[:x] = "x"
    end

    assert_raise NameError do
      puts ds[:x]
    end
  end


  def test_variables_define_multi
    ds1 = @work.ds1
    ds2 = @work.ds2

    Variables.define ds1,ds2 do |v|
      v.create :rownum, :type => "number"
      v.create :retailer_key
      v.create :retailer_name
      v.create :physical_cases, :type => "number"
    end

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

    Variables.define ds1 do |v|
      v.create :rownum, :type => "number"
      v.create :retailer_key
      v.create :retailer_name
      v.create :physical_cases, :type => "number"
    end

    Variables.define ds2 do |v|
      v.import ds1, :all
    end

    Variables.define ds3 do |v|
      v.import ds1, :keep => [:retailer_key,:physical_cases]
    end

    Variables.define ds4 do |v|
      v.import ds1, :drop => [:rownum,:retailer_key]
    end
    
  end



=begin

  def _COMPLETE_test_variable_create
    Datastep.create @work.ds1 do |ds1|
      Variables.define ds1 do |v|
        v.var :rownum, :type => "number"
        v.var :retailer_key
        v.var :physical_cases, :type => "number"
      end

      for i in 1..10
        ds1[:retailer_key] = "0123456789"
        ds1[:physical_cases] = (rand()*100).to_i
        ds1[:counter] = 1

        ds1.output
      end
    end

    count_rows = 0
    Datstep.read @work.ds1 do |ds1|
      count_rows += ds1[:counter]

      if ds1._N_ < 2
        ds1.row_to_log
        assert_equal "0123456789", ds1[:retailer_key], "Problem assigning variable :retailer_key"
      end
    end

    assert_equal 100, count_rows, "Expected 100 rows, found #{count_rows}"

    end
  end


  def _test_variable_create
    Datastep.create @work.have do |have|
f=begin
      have.var :retailer_key, :type => "string"
      have.var :physical_cases, :type => "number"
      have.var :counter, :type => "number"
f=end


# Is there really any reason to put this in a block, other than it looks nice?
#  Would there potentially be pre/post variable creation validation checks
#  that I may need to do?
      have.define_variables do |v|
        v.define :rownum, :type => "number"
        v.define :retailer_key, :type => "string"
        v.define :physical_cases, :type => "number"
      end

# What about something like this for multiple datasets
#  this seems to provide some utility to defining variables in blocks
#  and would enable pre/post checks if needed
#  Post-check would be to ensure that positions are sequential and non-duplicated
      Datastep.define_variables ds1,ds2 do |v|
        v.define :rownum, :type => "number"
        v.define :retailer_key, :type => "string"
        v.define :physical_cases, :type => "number"
      end

      Datastep.define_variables ds1 do |v|
        v.define :in_ds1, :type => "string"
      end
      Datastep.define_variables ds2 do |v|
        v.define :in_ds2, :type => "string"
      end

# But maybe Datastep is confusing, because there's no "stepping" going on here
# what about something like this
# preferably, the dataset objects would only have access to var within the block
      Variables.define ds1,ds2 do |v|
        v.var :rownum, :type => "number"
        v.var :retailer_key, :type => "string"
        v.var :physical_cases, :type => "number"
      end



      for i in 1..100
        have[:retailer_key] = "0123456789"
        have[:physical_cases] = (rand()*100).to_i
        have[:counter] = 1

        have.output
      end
    end

    count_rows = 0
    Datstep.read @work.have do |have|
      count_rows += have[:counter]

      if have._N_ < 2
        have.row_to_log
        assert_equal "0123456789", have[:retailer_key], "Problem assigning variable :retailer_key"
      end
    end

    assert_equal 100, count_rows, "Expected 100 rows, found #{count_rows}"
  end


  def test_variable_copy
    Datastep.create @work.ds1,@work.ds2 do |ds1,ds2|
      have.var :retailer_key, :type => "string"
      have.var :physical_cases, :type => "number"
      have.var :counter, :type => "number"

      have.define_variables do
        var :rownum, :type => "number"
        var :retailer_key, :type => "string"
        var :physical_cases, :type => "number"
      end

      for i in 1..100
        have[:retailer_key] = "0123456789"
        have[:physical_cases] = (rand()*100).to_i
        have[:counter] = 1

        have.output
      end
    end

    count_rows = 0
    Datstep.read @work.have do |have|
      count_rows += have[:counter]

      if have._N_ < 2
        have.row_to_log
        assert_equal "0123456789", have[:retailer_key], "Problem assigning variable :retailer_key"
      end
    end

    assert_equal 100, count_rows, "Expected 100 rows, found #{count_rows}"
  end
=end
end


