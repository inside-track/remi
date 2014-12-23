require 'remi_spec'

describe VariableSet do

  # Pre-define some variables to be used in variableset tests
  let(:shared_vars) do
    {
      :account_id => (VariableMeta.new :length => 18, :label => 'Account Id'),
      :name       => (VariableMeta.new :length => 80, :label => 'Account Name')
    }
  end

  subject(:example_set) { VariableSet.new :account_id => shared_vars[:account_id], :name => shared_vars[:name], :balance => { :type => 'currency' } }

  describe 'equivalent ways to define a variable set' do
    specify 'directly using an array accesor' do
      testset = VariableSet.new 
      testset[:account_id] = shared_vars[:account_id]
      testset[:name]       = shared_vars[:name]
      testset[:balance]    = { :type => 'currency' }
      expect(testset).to eq example_set
    end

    specify 'in a block, using the var method' do
      expect(
        VariableSet.new do
          var :account_id, shared_vars[:account_id]
          var :name,       shared_vars[:name]
          var :balance,    { :type => 'currency' }
        end
      ).to eq example_set
    end
  end

  it 'returns a variable when referenced using an array accessor' do
    expect(example_set[:name].meta).to eq shared_vars[:name]
  end

  it 'has all of the keys defined' do
    expect(example_set.keys).to match_array([:name, :account_id, :balance])
  end

  describe 'importing variable sets' do
    let(:derived_set) do
      VariableSet.new do
        like example_set
        var :group
      end
    end

    it 'has the original set of variables' do
      expect(derived_set).to include(*example_set.keys)
    end

    it 'has the new variable too' do
      expect(derived_set).to include(:group)
    end
  end

  describe 'modifying variable sets' do
    subject(:original_set) do
      VariableSet.new do
        like example_set
        var :to_drop
        var :to_also_drop
      end
    end

    shared_examples 'surviving variables' do
      specify { expect(subject).to include(:account_id, :name, :balance) }
      specify { expect(subject).not_to include(:to_drop, :to_also_drop) }
    end

    context 'non-destructively dropped' do
      subject(:modified_set) { original_set.drop_vars :to_drop, :to_also_drop }
      specify { modified_set; expect(original_set).to include(:to_drop, :to_also_drop) }
      it_behaves_like 'surviving variables'
    end

    context 'destructively dropped' do
      before { original_set.drop_vars! :to_drop, :to_also_drop }
      it_behaves_like 'surviving variables'
    end

    context 'dropped within a block' do
      before do
        original_set.modify do
          drop_vars :to_drop, :to_also_drop
        end
      end

      it_behaves_like 'surviving variables'
    end

    context 'non-destructively kept' do
      subject(:modified_set) { original_set.keep_vars :account_id, :name, :balance }
      specify { modified_set; expect(original_set).to include(:to_drop, :to_also_drop) }
      it_behaves_like 'surviving variables'
    end

    context 'destructively kept' do
      before { original_set.keep_vars! :account_id, :name, :balance }
      it_behaves_like 'surviving variables'
    end

    context 'kept within a block' do
      before do
        original_set.modify do
          keep_vars :account_id, :name, :balance
        end
      end

      it_behaves_like 'surviving variables'
    end

    context 'modifying metadata within a block' do
      it 'does not change variable indexes when the variable already exists' do
        expect {
          original_set.modify do
            var :account_id, label: 'Some new label'
          end
        }.not_to change {
          original_set.collect { |k, v| [k, v.index] }
        }
      end

      it 'adds a new variable when the variable does not already exist' do
        expect {
          original_set.modify do
            var :new_field
          end
        }.to change {
          original_set.size
        }.by(1)
      end

    end

  end

  describe 'how variables are ordered' do
    it 'loops through variables in the indexed order' do
      index_order = example_set.collect { |name, var| var.index }
      expect(index_order).to eq 0.upto(example_set.size-1).to_a
    end

    context 'keeping/dropping variables' do
      it 're-indexes remaining variables on drop' do
        expect { example_set.drop_vars!(:name) }.to change { example_set[:balance].index }.from(2).to(1)
      end

      it 're-indexes remaining variables on keep' do
        expect { example_set.keep_vars!(:name) }.to change { example_set[:name].index }.from(1).to(0)
      end
    end

    context 'reordering variables sets' do
      let(:original_set) do
        VariableSet.new do
          var :var1
          var :var2
          var :var3
          var :var4
        end
      end

      let(:reorder_set) { original_set.reorder :var3, :var2 }

      it 'should reorder the variables' do
        expect { reorder_set }.to change { original_set.collect { |name, v| name }}
          .from([:var1, :var2, :var3, :var4])
          .to(  [:var3, :var2, :var1, :var4])
      end

      it 'reindexing should not change the indexes on a reordered set' do
        expect { reorder_set.reindex }.not_to change { reorder_set.collect { |name, v| name }}
      end

    end

    context 'combining variablesets' do
      let(:derived_set) do
        VariableSet.new do |v|
          var :account_type
          var :name,        comment: 'this is overwritten'
          like example_set
        end
      end

      it 'contains the combination of variables in the right order' do
        expect([:account_type, :name, :account_id, :balance].collect { |name| derived_set[name].index }).to eq [0,1,2,3]
      end

      it 'overwrites metadata with the last one defined' do
        expect(derived_set[:name].meta).not_to include(:comment)
      end
    end
  end
end


