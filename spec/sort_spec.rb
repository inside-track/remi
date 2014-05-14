require "remi_spec"

=begin
unfinished test that needs to be migrated to a spec when ready

class Test_sort < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    Datastep.create @work.have do |ds|

      myvar = []
      Variables.define ds do |v|
        for ivar in 0..4
          myvar << "myvar_#{('A'..'Z').to_a[ivar]}"
          v.create myvar[ivar]
        end
      end

      for irow in 1..100

        ds[myvar[0]] = ('A'..'D').to_a[rand(4)]
        ds[myvar[1]] = (rand()*100).to_i
        for ivar in 2..4
          ds[myvar[ivar]] = rand()
        end

        ds.write_row
      end
    end
  end

  def teardown
    # Add a delete data function
  end


  def test_sort
    Datastep.sort @work.have, out: @work.sorted, by: [:myvar_A,:myvar_B]

    last = { :myvar_A => nil, :myvar_B => nil }
    Datastep.read @work.sorted do |ds|
      def ds.assign_last(last = {})
        last[:myvar_A] = self[:myvar_A]
        last[:myvar_B] = self[:myvar_B]
      end

      if ds._N_ == 1
        ds.assign_last(last)
        next
      end

      sorted = ds[:myvar_A] <=> last[:myvar_A]
      sorted = (sorted != 0) ? sorted : ds[:myvar_B] <=> last[:myvar_B]

      if sorted < 0
        assert_equal true, sorted >= 0, "Dataset not sorted | Last: [#{last[:myvar_A]}, #{last[:myvar_B]}]; Current: [#{ds[:myvar_A]}, #{ds[:myvar_B]}]"
      end

      ds.assign_last(last)
    end
  end
end


=end
