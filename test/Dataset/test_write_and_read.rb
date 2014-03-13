require "test_remi"

class Test_write_and_read < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}
    work = @work

    Datastep.create work.have do |have|
      have.define_variables do
        var :rownum, :type => "number"
        var :retailer_key, :type => "string"
        var :physical_cases, :type => "number"
      end

      for i in 1..100
        have[:rownum] = i
        have[:retailer_key] = "0123456789"
        have[:physical_cases] = (rand()*100).to_i

        have.output
      end
    end

  end

  def teardown
    # Add a delete data function
  end

  def test_write_and_read
    work = @work
    count_have_rows = 0

    Datastep.create work.want do |want|
      want.define_variables do
        var :mofo, :type => "number"
        var_import(work.have)
        var :russel, :type => "string"
      end

      Datastep.read work.have do |have|
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


