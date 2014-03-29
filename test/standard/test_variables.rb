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

    Variables.describe ds do |v|
      v.define :rownum, :type => "number"
      v.define :retailer_key
      v.define :retailer_name
      v.define :physical_cases, :type => "number"
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


