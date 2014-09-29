module Remi
  class RowSet

    def initialize(lag_rows: 1, lead_rows: 1, by_groups: [])

      @rows = {}
      @lead_rows = lead_rows
      @lag_rows = lag_rows
      initialize_rows
      
      @by_groups = Array(by_groups)
      @by_first = Array.new(@by_groups.length)
      @by_last = Array.new(@by_groups.length)
      @has_by_groups = @by_groups.length > 0
    end

    
    def add(row)
      row.row_number ||= (@rows[@lead_rows].row_number || 0) + 1
      (-@lag_rows).upto(@lead_rows - 1).each do |i|
        @rows[i] = @rows[i+1]
      end
      @rows[@lead_rows] = row

      update_by_groups if has_by_groups?
    end

    def [](idx)
      @rows[0][idx]
    end

    def curr
      @rows[0]
    end

    def prev
      @rows[-1]
    end

    def next
      @rows[1]
    end

    def lag(n)
      @rows[-n]
    end

    def lead(n)
      @rows[n]
    end

    def has_by_groups?
      @has_by_groups
    end

    def update_by_groups
      parent_first = false
      parent_last = false
      @by_groups.each_with_index do |grp, idx|
        @by_first[idx] = (self[grp] != self.prev[grp]) or parent_first
        @by_last[idx]  = (self[grp] != self.next[grp]) or parent_last or self.curr.eof

        parent_first = @by_first[idx]
        parent_last = @by_last[idx]
      end
    end
    
    def first(idx=0)
      @by_first[idx]
    end
    
    def last(idx=0)
      @by_last[idx]
    end


    private

    def initialize_rows
      (-@lag_rows).upto(@lead_rows).each do |i|
        @rows[i] = Row.new(Array.new)
      end
    end

  end
end
