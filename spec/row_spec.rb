require 'remi_spec'

describe Row do

  context 'creating a row object' do
    it 'is initialized with an array' do
      expect(Row.new([1,2,3])).to be_a(Row)
    end

    it 'can optionally set an last_row flag' do
      expect(Row.new([1,2,3], last_row: true)).to be_a(Row)
    end
  end

  context 'using a row object' do
    before { @row = Row.new([1,2,3], last_row: true, row_number: 83) }

    it 'returns the length' do
      expect(@row.length).to eq 3
    end

    it 'tracks the last_row flag' do
      expect(@row.last_row).to eq true
    end

    it 'tracks the row_number' do
      expect(@row.row_number).to eq 83
    end
  end
end

