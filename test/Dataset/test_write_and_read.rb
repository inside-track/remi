require "test_remi"

class Test_write_and_read < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_write_and_read
    work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}

    datastep work.have do |have|
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


    n_have_rows = 0

    datastep work.want do |want|
      want.define_variables do
        var :mofo, :type => "number"
        var_import(work.have)
        var :russel, :type => "string"
      end

      read work.have do |have|
        want.set_values(have)
        want[:mofo] = "TD-#{have[:retailer_key]}"
        want[:russel] = "RUSSEL!!!"

        n_have_rows = n_have_rows + 1

        want.output
      end
    end

    read work.want do |want|
      want.row_to_log if want._N_ < 10
    end

    assert_equal 100, n_have_rows, "Expected 100 rows, found #{n_have_rows}"

  end
end


