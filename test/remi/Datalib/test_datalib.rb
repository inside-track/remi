$LOAD_PATH << "#{File.dirname(__FILE__)}/../.."
require "test_remi"

class Test_define_lib < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_define_lib
    work = Datalib.new :directory => {:dirname => "#{ENV['HOME']}/Desktop/work"}
    assert_kind_of Datalib, work, "work is not a Datalib"
  end

end


