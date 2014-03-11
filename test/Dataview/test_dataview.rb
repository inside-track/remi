require "test_remi"

class Test_Dataview < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_dataview
    v = Dataview.new
    v.create_table
    v.table_tpl
    v.view_table

    # Want:
=begin
    Dataset.view dataview work.mydata
=end

  end
end


