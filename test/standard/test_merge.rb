require "test_remi"

# REVISE THIS WHEN I HAVE BY GROUPS


class Test_merge < Test::Unit::TestCase

  def setup
    @work = Datalib.new :directory => {:dirname => RemiConfig.work_dirname}

    data_A = [
              ["A",1,"in A row 1"],
              ["A",1,"in A row 2"],
              ["A",2,"in A row 3"],
              ["A",2,"in A row 4"],
              ["A",4,"in A row 5"],
              ["A",4,"in A row 6"],
              ["A",4,"in A row 7"],
              ["A",5,"in A row 8"]
             ]

    data_B = [
              ["B",1,"in B row 1","Beta 1"],
              ["B",3,"in B row 3","Beta 3"],
              ["B",4,"in B row 4","Beta 4"],
              ["B",5,"in B row 5","Beta 5"],
              ["B",6,"in B row 6","Beta 6"]
             ]

    # I WILL ALSO NEED A MANY TO MANY EXAMPLE

    Datastep.create @work.data_A, @work.data_B  do |dsA,dsB|
      Variables.define dsA, dsB do |v|
        v.create :set_flag
        v.create :key, :type => "number"
        v.create :shared_value
      end

      Variables.define dsB do |v|
        v.create :lkp_value
      end

      data_A.each do |row|
        dsA.row = row
        dsA.write_row
      end

      data_B.each do |row|
        dsB.row = row
        dsB.write_row
      end
    end
  end

  def teardown
    # Add a delete data function
  end

  def _test_merge

    # Also make sure to see what's happening with retained values

    merge_keys = [:key]

    Datastep.create @work.data_C do |ds|

      ds1 = @work.data_A
      ds2 = @work.data_B

      Variables.define ds do |v|
        v.import ds1
        v.import ds2
      end

      ds1_nil = @work.ds1_nil
      Variables.define ds1_nil do |v|
        v.import ds1
      end
      ds1_nil.row = Array.new(ds1.length)

      ds2_nil = @work.ds2_nil
      Variables.define ds2_nil do |v|
        v.import ds2
      end
      ds2_nil.row = Array.new(ds2.length)

      ds1.open_for_read
      ds2.open_for_read

      begin
        ds1.read_row
        ds2.read_row


        prev_compare = (ds1[:key] <=> ds2[:key])
        while !(ds1.EOF or ds2.EOF)

          this_compare = (ds1[:key] <=> ds2[:key])
          puts "ds1: #{ds1.row} | ds2: #{ds2.row} | #{this_compare} | #{ds1.prev(:key)} | #{ds2.prev(:key)}"

          case ds1[:key] <=> ds2[:key]
          when 0
            ds.read_row_from ds1
            prev_ds1_key = ds1[:key]
            ds1.read_row

            ds.read_row_from ds2
            prev_ds2_key = ds2[:key]
            ds2.read_row

          when -1
            ds.read_row_from ds2_nil if ds1[:key] != ds1.prev(:key)
            ds.read_row_from ds1
            ds1.read_row
          when 1
            ds.read_row_from ds1_nil if ds2[:key] != ds2.prev(:key)
            ds.read_row_from ds2
            ds2.read_row
          end

          ds.write_row

          prev_compare = this_compare
        end

        while !ds1.EOF
          ds.read_row_from ds1
          ds1.read_row
          ds.write_row
        end

        while !ds2.EOF
          ds.read_row_from ds2
          ds2.read_row
          ds.write_row
        end
        
      ensure
        ds1.close
        ds2.close
      end
    end


    Dataview.view @work.data_A
    Dataview.view @work.data_B
    Dataview.view @work.data_C

  end


end


