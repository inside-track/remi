module Remi
  class RowSet

    def initialize(lag_rows: 1, lead_rows: 1, by_groups: [])

      @rows = {}
      (-lag_rows).upto(lead_rows).each do |i|
        @rows[i] = Row.new(Array.new)
      end

      @lead_rows = lead_rows
      @lag_rows = lag_rows
      
      @by_groups = by_groups
    end

    def add(row)
      row.row_number ||= (@rows[@lead_rows].row_number || 0) + 1
      (-@lag_rows).upto(@lead_rows - 1).each do |i|
        @rows[i] = @rows[i+1]
      end
      @rows[@lead_rows] = row
    end

    def [](idx)
      @rows[0][idx]
    end

    def prev(idx)
      @rows[-1][idx]
    end

    def next(idx)
      @rows[1][idx]
    end

    def lag(n,idx)
      @rows[-n][idx]
    end

    def lead(n,idx)
      @rows[n][idx]
    end

    def has_by_groups?
      @by_groups.lengths > 0
    end

    def initialize_by_groups
    end

    def update_by_groups
    end
    
    def first(*idx)
    end
    
    def last(*idx)
    end
  end
end
