require 'remi_spec'

describe Row do

  shared_examples 'a row' do |length: nil, last_row: nil, row_number: nil|
    it 'returns the length' do
      expect(@row.length).to eq length
    end

    it 'returns the size' do
      expect(@row.size).to eq length
    end

    it 'tracks the last_row flag' do
      expect(@row.last_row).to eq last_row
    end

    it 'tracks the row_number' do
      expect(@row.row_number).to eq row_number
    end

    it 'can clear the row with nil values' do
      expect { @row.clear }.to change { @row.to_a }.to([nil] * length)
    end
  end


  context 'using a row object by index' do
    before { @row = Row.new([1,2,3], last_row: true, row_number: 83) }

    it_should_behave_like 'a row', length: 3, last_row: true, row_number: 83

    it 'returns the correct values by index' do
      expect(@row[0]).to eq 1
      expect(@row[1]).to eq 2
      expect(@row[2]).to eq 3
    end

    it 'sets a value by index' do
      expect { @row[1] = 200 }.to change { @row[1] }.from(2).to(200)
    end
  end

  context 'using a row object by key map' do
    before do
      key_map = {
        :one => double('VariableWithIndex', :index => 0),
        :two => double('VariableWithIndex', :index => 1),
        :three => double('VariableWithIndex', :index => 2)
      }

      @row = Row.new([1,2,3], key_map: key_map)
    end

    it_should_behave_like 'a row', length: 3, last_row: false, row_number: nil

    it 'returns the correct values by key map' do
      expect(@row[:one]).to eq 1
      expect(@row[:two]).to eq 2
      expect(@row[:three]).to eq 3
    end

    it 'sets a value by key map' do
      expect { @row[:two] = 200 }.to change { @row[:two] }.from(2).to(200)
    end
  end
end
