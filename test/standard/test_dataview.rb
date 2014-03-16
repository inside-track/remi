require "test_remi"

class Test_Dataview < Test::Unit::TestCase

  def setup
  end

  def teardown
  end



  def test_dataview

    work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    myvar = []
    Datastep.create work.have do |have|
      have.define_variables do
        var :rownum, :type => "number"
        var :retailer_key, :type => "string"
        var :physical_cases, :type => "number"

        for i in 1..5
          myvar << "myvar_#{i}".to_sym
          var myvar[i-1], :type => "string"
        end

      end

      for i in 1..1020
        have[:rownum] = i
        have[:retailer_key] = "TD-#{rand_alpha(7)}"
        have[:physical_cases] = (rand()*100).to_i

        for i in 1..5
          have[myvar[i-1]] = rand_alpha(3)
        end

        have.output
      end
    end

    Dataview.view work.have

  end
end


