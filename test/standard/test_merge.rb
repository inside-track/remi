require "test_remi"

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

  def test_wtf
  end

  def test_merge

    # Also make sure to see what's happening with retained values

    merge_keys = [:key]

    Datastep.create @work.data_C do |ds|

      ds1 = @work.data_A
      ds2 = @work.data_B

      Variables.define ds do |v|
        v.import ds1
        v.import ds2
      end

      buffer_ds = @work.buffer_ds
      Variables.define buffer_ds do |v|
        v.import ds
      end

      ds1.open_for_read
      ds2.open_for_read

      begin
        ds1.read_row
        ds2.read_row
        
        while !(ds1.EOF and ds2.EOF)
          puts "-- Comparing row --"
          puts "ds1: #{ds1.row} - key:#{ds1[:key]}"
          puts "ds2: #{ds2.row} - key:#{ds2[:key]}"

          key_compare = ds1[:key] <=> ds2[:key]

          puts "key_compare: #{key_compare}"
          puts "ds1.EOF:#{ds1.EOF}/ds1.EOF:#{ds1.EOF}"

          #hmmmm
          buffer_ds.row = Array.new(ds.length)


          if key_compare == 0
            buffer_ds.read_row_from ds1
            ds1.read_row
            buffer_ds.read_row_from ds2
            ds2.read_row
          elsif ds2.EOF
            ds.read_row_from ds1
            ds1.read_row
          elsif ds1.EOF
            ds.read_row_from ds2
            ds2.read_row
          elsif key_compare == -1
            ds.read_row_from ds1
            ds1.read_row
          elsif key_compare == 1
            ds.read_row_from ds2
            ds2.read_row
          end

          ds.write_row
          puts "ds1.EOF:#{ds1.EOF}/ds2.EOF:#{ds2.EOF}"
          puts "WTF: #{!(ds1.EOF and ds2.EOF)}"
#          break

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


