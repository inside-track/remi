require "test_remi"

class Test_write_and_read < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
  end

  def teardown
    # Add a delete data function
  end

  def test_write
    Datastep.create @work.have do |have|
      Variables.define have do |v|
        v.create :rownum, :type => "number"
        v.create :retailer_key
        v.create :physical_cases, :type => "number"
      end

      for i in 1..100
        have[:rownum] = i
        have[:retailer_key] = "0123456789"
        have[:physical_cases] = (rand()*100).to_i

        have.output
      end
    end
  end

  def test_read
    test_write # so test_write isn't always happening first...think I need a nested test suite

    count_have_rows = 0
    Datastep.read @work.have do |have|
      if have._N_ < 2
        have.row_to_log
        assert_equal "0123456789", have[:retailer_key], "Problem reading variable :retailer_key"
      end
      count_have_rows += 1
    end

    assert_equal 100, count_have_rows, "Expected 100 rows, found #{count_have_rows}"
  end


  def _test_read_to_write
    Datastep.create @work.want do |want|
      Varibles.define want do |v|
        v.create :mofo, :type => "number"
        v.import @work.have
        v.create :russel
      end

      want.define_variables do
        var :mofo, :type => "number"
        var_import(work.have)
        var :russel, :type => "string"
      end

      Datastep.read @work.have do |have|
        want.set_values(have)
        want[:mofo] = "TD-#{have[:retailer_key]}"
        want[:russel] = "RUSSEL!!!"

        if want._N_ < 2
          want.row_to_log
          assert_equal "0123456789", want[:retailer_key], "Problem assigning variable :retailer_key"
        end

        count_have_rows = count_have_rows + 1

        want.output
      end
    end

    assert_equal 100, count_have_rows, "Expected 100 rows, found #{count_have_rows}"

  end
end


