require "test_remi"

class Test_Dataview < Test::Unit::TestCase

  def setup
  end

  def teardown
  end



  def test_dataview
    work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    Datastep.create work.have do |have|

      myvar = []
      Variables.define have do |v|
        v.create :rownum, :type => "number"
        v.create :retailer_key
        v.create :physical_cases, :type => "number"
        
        for i in 1..5
          myvar << "myvar_#{i}".to_sym
          v.create myvar[i-1]
        end
      end
      puts have

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


