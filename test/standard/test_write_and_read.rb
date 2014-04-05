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

        have.write_row
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


  def test_read_to_write
    test_write # need nested test suite!!!!

    Datastep.create @work.want do |want|
      Variables.define want do |v|
        v.create :alt_key
        v.import @work.have
        v.create :russell
      end

      # Define an instance method so we don't have to duplicate this code
      # in the dummy row and the read row
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


    count_want_rows = 0
    Datastep.read @work.want do |want|
      if want._N_ < 3
        want.row_to_log
        if want._N_ == 1
          assert_equal "TD-0000000000", want[:alt_key], "Problem assigning dummy variable :alt_key"
        else
          assert_equal "TD-0123456789", want[:alt_key], "Problem assigning read variable :alt_key"
        end
        assert_equal "RUSSELL!!", want[:russell], "Problem assigning constant :russell"
        assert_equal want._N_, want[:rownum], "Problem assigning rownumber :rownum"
      end

      count_want_rows = count_want_rows + 1
    end

    assert_equal 101, count_want_rows, "Expected 101 rows, found #{count_want_rows}"
  end


  def write_some_tests_for_keep_drop_too!
  end


end


