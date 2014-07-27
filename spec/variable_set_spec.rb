require 'remi_spec'

describe VariableSet do

  # Pre-define some dummy shared variables to be used in variable sets
  let(:shared_vars) do
    {
      :account_id => (Variable.new :length => 18, :label => "Account Id"),
      :name       => (Variable.new :length => 80, :label => "Account Name"),
    }
  end

  describe "A variable set is a collection of variables" do

    context "can be created in one line" do
      subject(:varset) { VariableSet.new :account_id => shared_vars[:account_id], :name => shared_vars[:name] }

      it { should have_keys(:account_id, :name) }

      context "using an array accessor to return a variable" do
        specify { expect(subject[:name].meta).to eq shared_vars[:name] }
      end
    end

    context "can be defined in a block" do
      let(:varset) do
        account_id = shared_vars[:account_id]
        name       = shared_vars[:name]
        VariableSet.new do
          var :account_id => account_id
          var :name       => name
          var :balance    => { :type => "currency" }
        end
      end

      specify { expect(varset).to have_keys :account_id, :name, :balance }
      specify { expect(varset[:name].meta).to be_a Variable }
      specify { expect(varset[:balance].meta).to be_a Variable }

      context "can be derived from other variable sets" do
        let(:varset_derived) do
          varset_origin = varset

          VariableSet.new do
            like varset_origin
            var :address => {}
          end
        end

        specify { expect(varset_derived).to have_keys :account_id, :name, :balance, :address }
      end

    end
  end

  describe "Modifying variable sets" do
    subject(:varset) do
      VariableSet.new do
        var :account_id  => { :length => 18 }
        var :drop_me     => { :type => "currency" }
        var :name        => {}
        var :drop_me_too => {}
      end
    end

    shared_examples "surviving variables" do
      specify { expect(subject).to have_keys(:account_id, :name) }
      specify { expect(subject).not_to have_keys(:drop_me, :drop_me_too) }
    end

    context "can be non-destructively dropped" do
      subject(:varset_derived) { varset.drop_vars :drop_me, :drop_me_too }
      it_behaves_like "surviving variables"
    end

    context "can be destructively dropped" do
      before { varset.drop_vars! :drop_me, :drop_me_too }
      it_behaves_like "surviving variables"
    end

    context "can be non-destructively kept" do
      subject(:varset_derived) { varset.keep_vars :account_id, :name }
      it_behaves_like "surviving variables"
    end

    context "can be destructively kept" do
      before { varset.keep_vars! :account_id, :name }
      it_behaves_like "surviving variables"
    end

    context "can be modified in a block" do
      before do
        varset.modify! do
          var :account_id => { :length => 21 }
        end
      end

      specify { expect(varset[:account_id].meta[:length]).to eq 21 }

      context "with drop method specified without a bang" do
        before do
          varset.modify! do
            drop_vars :drop_me, :drop_me_too
          end
        end

        it_behaves_like "surviving variables"
      end

      context "with keep method specified without a bang" do
        before do
          varset.modify! do
            keep_vars :account_id, :name
          end
        end

        it_behaves_like "surviving variables"
      end

    end

  end

  describe "Ordering variables" do
  end
end


