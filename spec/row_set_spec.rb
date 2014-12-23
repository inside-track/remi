require 'remi_spec'

describe RowSet do

  before do
    @test_data = {}
    1.upto(6).each do |i|
      @test_data[i-3] = [i, i*2, i*3]
    end
  end

  it 'can add a single row to the rowset' do
    expect { RowSet.new.add(Row.new([1,2,3])) }.not_to raise_error
  end

  describe 'a rowset loaded with data' do
    before do
      @rowset = RowSet.new(lag_rows: 2, lead_rows: 2)
      (-2).upto(2).each do |i|
        @rowset.add(Row.new(@test_data[i]))
      end
    end

    it 'returns the current row using the array accessor' do
      expect(@rowset[0..2]).to eq @test_data[0]
    end

    it 'returns the previous row when requested' do
      expect(@rowset.prev[0..2]).to eq @test_data[-1]
    end

    it 'returns the next row when requested' do
      expect(@rowset.next[0..2]).to eq @test_data[1]
    end

    it 'returns the lag 2 row when requested' do
      expect(@rowset.lag(2)[0..2]).to eq @test_data[-2]
    end

    it 'returns the lead 2 row when requested' do
      expect(@rowset.lead(2)[0..2]).to eq @test_data[2]
    end

    describe 'adding another row to a rowset already loaded with data' do
      before { @rowset.add(Row.new(@test_data[3], last_row: true)) }

      it 'changes which row is current' do
        expect(@rowset[0..2]).to eq @test_data[1]
      end

    end
  end

  describe 'single by groups' do
    before do
      @rowset = RowSet.new(by_groups: 1)
    end

    # The value of a variable on the next row is either the same or different.
    # The value of a variable on the previous row is either the same or different.
    # Test all possibilities.
    ['A','X'].each do |gnext|
      ['A','X'].each do |gprev|
        context "Pattern: #{gnext}A#{gprev}" do
          before do
            @rowset.add(Row.new(['prev', gprev]))
            @rowset.add(Row.new(['curr', 'A']))
            @rowset.add(Row.new(['next', gnext]))
          end

          it 'returns correct first flag' do
            expect(@rowset.first).to eq (gprev != 'A')
          end

          it 'returns correct last flag' do
            expect(@rowset.last).to eq (gnext != 'A')
          end

        end
      end
    end

    # Also need to test edge cases that happen at the beginning and end of
    # a file.

    context 'first row, next row different' do
      before do
        @rowset.add(Row.new(['curr', 'A']))
        @rowset.add(Row.new(['next', 'X']))
      end

      specify { expect(@rowset.first).to eq true }
      specify { expect(@rowset.last).to eq true }
    end

    context 'first row, next row same' do
      before do
        @rowset.add(Row.new(['curr', 'A']))
        @rowset.add(Row.new(['next', 'A']))
      end

      specify { expect(@rowset.first).to eq true }
      specify { expect(@rowset.last).to eq false }
    end

    context 'last row, prev row different' do
      before do
        @rowset.add(Row.new(['prev', 'X']))
        @rowset.add(Row.new(['curr', 'A'], last_row: true))
        @rowset.add(Row.new(['next', 'A'], last_row: true)) # assume the last rows get repeated for some reason
      end

      specify { expect(@rowset.first).to eq true }
      specify { expect(@rowset.last).to eq true }
    end

    context 'last row, prev row same' do
      before do
        @rowset.add(Row.new(['prev', 'A']))
        @rowset.add(Row.new(['curr', 'A'], last_row: true))
        @rowset.add(Row.new(['next', 'A'], last_row: true)) # assume the last rows get repeated for some reason
      end

      specify { expect(@rowset.first).to eq false }
      specify { expect(@rowset.last).to eq true }
    end
  end

  describe 'multiple by groups' do
    before do
      @rowset = RowSet.new(by_groups: [1,2])
    end

    # With two by group variables, there are 16 combinations of prev/next to test.
    # Assume edge cases are handled with single by group tests.
    ['A','X'].each do |gnext|
      ['A','X'].each do |gprev|
        ['a','x'].each do |snext|
          ['a','x'].each do |sprev|

            context "Pattern: #{gprev}#{sprev}|Aa|#{gnext}#{snext}" do
              before do
                @rowset.add(Row.new(['prev', gprev, sprev]))
                @rowset.add(Row.new(['curr', 'A', 'a']))
                @rowset.add(Row.new(['next', gnext, snext]))
              end

              it 'returns correct first flag for group' do
                expect(@rowset.first(1)).to eq (gprev != 'A')
              end

              it 'returns correct first flag for subgroup' do
                expect(@rowset.first(2)).to eq (sprev != 'a' || gprev != 'A')
              end

              it 'returns correct last flag for group' do
                expect(@rowset.last(1)).to eq (gnext != 'A')
              end

              it 'returns correct last flag for subgroup' do
                expect(@rowset.last(2)).to eq (snext != 'a' || gnext != 'A')
              end
            end
          end
        end
      end

    end
  end
end
