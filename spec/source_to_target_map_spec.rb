require_relative 'remi_spec'

describe SourceToTargetMap do
  let(:df) do
    Remi::DataFrame::Daru.new(
      [
        ['a1','b1','c1', ['d',1]],
        ['a2','b2','c2', ['d',2]],
        ['a3','b3','c3', ['d',3]],
      ].transpose,
      order: [:a, :b, :c, :d]
    )
  end


  let(:map) { SourceToTargetMap::Map.new(df, df) }

  describe 'one-to-one maps' do
    shared_examples_for 'one-to-one map' do
      it 'provides a value to the transform, and expects a return value' do
        expect(result).to eq ['a1prime', 'a2prime', 'a3prime']
      end

      it 'accepts chained transformations with the same source/target cardinality' do
        map.transform(->(v) { "#{v}-prime" })
        expect(result).to eq ['a1prime-prime', 'a2prime-prime', 'a3prime-prime']
      end
    end

    context 'standard use' do
      before { map.source(:a) .target(:aprime) .transform(->(v) { "#{v}prime" }) }

      let(:result) do
        map.execute
        df[:aprime].to_a
      end

      it_behaves_like 'one-to-one map'
    end

    context 'the source and target have the same name' do
      before { map.source(:a) .target(:a) .transform(->(v) { "#{v}prime" }) }

      let(:result) do
        map.execute
        df[:a].to_a
      end

      it_behaves_like 'one-to-one map'
    end

    context 'without any transforms' do
      before { map.source(:a) .target(:aprime) }

      let(:result) do
        map.execute
        df[:aprime].to_a
      end

      it 'copies data from source to target' do
        expect(result).to eq ['a1', 'a2', 'a3']
      end

    end

    context 'source and target dataframe are different' do
      let(:map) { SourceToTargetMap::Map.new(df, df_target) }

      context 'vectors referenced in the source only exist on the target' do
        let(:df_target) do
          Remi::DataFrame::Daru.new({ a_in_target: [ 'a1target', 'a2target', 'a3target' ] }, index: df.index)
        end

        before { map.source(:a_in_target) .target(:aprime) .transform(->(v) { "#{v}prime" }) }

        let(:result) do
          map.execute
          df_target[:aprime].to_a
        end

        it 'uses the target values' do
          expect(result).to eq ['a1targetprime', 'a2targetprime', 'a3targetprime']
        end
      end

      context 'vectors referenced in the source exist on both source and target' do
        let(:df_target) do
          Remi::DataFrame::Daru.new({ a: [ 'a1target', 'a2target', 'a3target' ] }, index: df.index)
        end

        before { map.source(:a) .target(:aprime) .transform(->(v) { "#{v}prime" }) }

        let(:result) do
          map.execute
          df_target[:aprime].to_a
        end

        it 'uses the source values' do
          expect(result).to eq ['a1prime', 'a2prime', 'a3prime']
        end
      end
    end

  end

  describe 'one-to-one maps where the source and target have the same name' do
    before { map.source(:a) .target(:a) .transform(->(v) { "#{v}prime" }) }

    let(:result) do
      map.execute
      df[:a].to_a
    end

    it 'provides a value to the transform, and expects a return value' do
      expect(result).to eq ['a1prime', 'a2prime', 'a3prime']
    end

    it 'accepts chained transformations with the same source/target cardinality' do
      map.transform(->(v) { "#{v}-prime" })
      expect(result).to eq ['a1prime-prime', 'a2prime-prime', 'a3prime-prime']
    end
  end

  describe 'many-to-one maps' do
    before { map.source(:a,:b) .target(:ab) .transform(->(row) { row[:a] + row[:b] }) }

    let(:result) do
      map.execute
      df[:ab].to_a
    end

    it 'provides a row to the transform, and expects a return value' do
      expect(result).to eq ['a1b1', 'a2b2', 'a3b3']
    end

    it 'accepts chained transformations with the same source/target cardinality' do
      map.transform(->(row) { "-#{row[:ab]}-" })
      expect(result).to eq ['-a1b1-', '-a2b2-', '-a3b3-']
    end
  end

  describe 'one-to-many maps' do
    before do
      map.source(:a) .target(:a_col, :a_row)
        .transform(->(row) {
          row[:a_col] = row[:a][0]
          row[:a_row] = row[:a][1]
        })
    end

    let(:result) do
      map.execute
      df[:a_col, :a_row].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
    end

    it 'provides a row to the transform and expects the row to be populated' do
      expect(result).to eq({ :a_col => ['a', 'a', 'a'], :a_row => ['1', '2', '3'] })
    end

    it 'accepts chained transformations with the same source/target cardinality' do
      map.transform(->(row) {
          row[:a_col] = "COL#{row[:a_col]}"
          row[:a_row] = "ROW#{row[:a_row]}"
        })

      expect(result).to eq({ :a_col => ['COLa', 'COLa', 'COLa'], :a_row => ['ROW1', 'ROW2', 'ROW3'] })
    end
  end

  describe 'many-to-many maps' do
    before do
      map.source(:b, :c) .target(:b_is_c, :c_is_b)
        .transform(->(row) {
          row[:b], row[:c] = row[:c], row[:b]
          row[:b_is_c] = row[:b]
          row[:c_is_b] = row[:c]
        })
    end

    let(:result) do
      map.execute
      df[:b_is_c, :c_is_b].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
    end

    it 'provides a row to the transform and expects the row to be populated' do
      expect(result).to eq({ :b_is_c => ['c1', 'c2', 'c3'], :c_is_b => ['b1', 'b2', 'b3'] })
    end

    it 'does not modify source vectors' do
      map.execute
      source_vectors = df[:b, :c].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
      expect(source_vectors).to eq({ :b => ['b1', 'b2', 'b3'], :c => ['c1', 'c2', 'c3'] })
    end

    it 'accepts chained transformations with the same source/target cardinality' do
      map.transform(->(row) {
          row[:b_is_c] = row[:b_is_c].reverse
          row[:c_is_b] = row[:c_is_b].reverse
        })

      expect(result).to eq({ :b_is_c => ['1c', '2c', '3c'], :c_is_b => ['1b', '2b', '3b'] })
    end
  end

  describe 'zero-to-one maps' do
    before do
      values = ['x1', 'x2', 'x3']
      map.target(:x) .transform(->() { values.shift })
    end

    let(:result) do
      map.execute
      df[:x].to_a
    end

    it 'expects no argument and expects a return value' do
      expect(result).to eq ['x1', 'x2', 'x3']
    end

    it 'accepts chained transformations with the same source/target cardinality' do
      map.transform(->() { 'useless' })
      expect(result).to eq ['useless']*3
    end
  end

  describe 'zero-to-many maps' do
    before do
      values = ['x1', 'x2', 'x3']
      map.target(:x_col, :x_row)
        .transform(->(row) {
          x = values.shift
          row[:x_col] = x[0]
          row[:x_row] = x[1]
        })
    end

    let(:result) do
      map.execute
      df[:x_col, :x_row].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
    end

    it 'provides a row to the transform and expects the row to be populated' do
      expect(result).to eq({ :x_col => ['x', 'x', 'x'], :x_row => ['1', '2', '3'] })
    end

    it 'accepts chained transformations with the same source/target cardinality' do
      map.transform(->(row) { row[:x_row] = "ROW#{row[:x_row]}" })
      expect(result).to eq({ :x_col => ['x', 'x', 'x'], :x_row => ['ROW1', 'ROW2', 'ROW3'] })
    end
  end

  describe 'vectors containing arrays' do
    it 'provides the array as a value the transform with one-to-one maps' do
      map.source(:d) .target(:dprime)
        .transform(->(v) { v.join('-') })
      map.execute

      expect(df[:dprime].to_a).to eq ['d-1', 'd-2', 'd-3']
    end

    it 'provides the array in the row with one-to-many maps' do
      map.source(:d) .target(:d_col, :d_row)
        .transform(->(row) {
          row[:d_col] = row[:d].first
          row[:d_row] = row[:d].last
        })
      map.execute

      result = df[:d_col, :d_row].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
      expect(result).to eq({ :d_col => ['d', 'd', 'd'], :d_row => [1, 2, 3] })
    end
  end

  describe 'using the DSL' do
    let(:sttm) do
      SourceToTargetMap.apply(df) do
        map source(:a) .target(:aprime)
          .transform(->(v) { "#{v}prime" })
        map source(:a) .target(:aprimeprime)
          .transform(->(v) { "#{v}prime" })
          .transform(->(v) { "#{v}-prime" })
        map source(:a, :d) .target(:ad)
          .transform(->(row) { "#{row[:a][0]}-#{row[:d].first}-#{row[:d].last}" })
      end
    end

    it 'allows one to specify multiple source-to-target maps in one block' do
      sttm
      result = df[:aprime, :aprimeprime, :ad].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
      expect(result).to eq({
        :aprime => ['a1prime', 'a2prime', 'a3prime'],
        :aprimeprime => ['a1prime-prime', 'a2prime-prime', 'a3prime-prime'],
        :ad => ['a-d-1', 'a-d-2', 'a-d-3']
      })
    end

    it 'returns a dataframe' do
      expect(sttm).to be_a(Remi::DataFrame::Daru)
    end
  end

  describe 'source and target dataframes differ', wip: true do
    it 'does not fail when the dataframe has been filtered' do
      some_df = Daru::DataFrame.new(
        {
          :id => [1,2,3,4,5],
          :something => ['x','','x','','x'],
          :name => ['one', 'two', 'three', 'four', 'five']
        }
      )

      filtered_df = some_df.where(some_df[:something].eq('x'))
      target_df = Remi::DataFrame::Daru.new([])

      Remi::SourceToTargetMap.apply(filtered_df, target_df) do
        map source(:id) .target(:id)
        map source(:name) .target(:name)
      end

      result = target_df[:id, :name].to_h.each_with_object({}) { |(k,v), h| h[k] = v.to_a }
      expect(result).to eq({
        :id => [1, 3, 5],
        :name => ['one', 'three', 'five']
      })
    end


  end


end
