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

    context 'accessing values by index' do
      it 'returns the correct value' do
        expect(@row[0]).to eq 1
        expect(@row[1]).to eq 2
        expect(@row[2]).to eq 3
      end

      it 'sets a value' do
        expect { @row[1] = 200 }.to change { @row[1] }.from(2).to(200)
      end
    end

    context 'accessing values using a key map' do
      before do
        key_map = {
          :one => double('VariableWithIndex', :index => 0),
          :two => double('VariableWithIndex', :index => 1),
          :three => double('VariableWithIndex', :index => 2)
        }

        @row_map = Row.new(@row.to_a, key_map: key_map)
      end

      it 'returns the correct values' do
        expect(@row_map[:one]).to eq 1
        expect(@row_map[:two]).to eq 2
        expect(@row_map[:three]).to eq 3
      end

      it 'sets a value' do
        expect { @row_map[:two] = 200 }.to change { @row_map[:two] }.from(2).to(200)
      end
    end
  end
end
