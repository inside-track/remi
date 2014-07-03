require 'remi_spec'

describe Variable do

  describe "A variable is an object that has a value and metadata" do

    context "which can be created in one line" do
      subject(:id) { Variable.new :some_meta => "That's so meta" }

      it { should have_key(:some_meta) }

      it "should define the mandatory type key" do
        subject.should have_key(:type)
      end

      context "using an array accessor to return metadata" do
        specify { expect(subject[:some_meta]).to eq "That's so meta" }
      end

      context "using an array accessor to modify metadata" do
        before { id[:some_meta] = "Metamodify" }
        specify { expect(id[:some_meta]).to eq "Metamodify" }
      end
    end

    context "and can be defined in a block" do
      let(:id) do
        Variable.define do
          meta :type      => "string"
          meta :length    => 18
          meta :some_meta => "More meta than you"
        end
      end

      specify { expect(id).to have_key(:length) }

      context "which is useful for importing variable metadata from other variables" do
        let(:id_derived) do
          id_origin = id # Don't understand why id not in scope of block below

          Variable.define do
            like id_origin
            meta :alt_meta => "Way, way meta"
          end
        end

        specify { expect(id_derived).to have_key(:some_meta) }
        specify { expect(id_derived).to have_key(:alt_meta) }
      end
    end
  end

  describe "Modifying metadata" do
    subject(:id) do
      Variable.define do
        meta :type      => "string"
        meta :length    => 18
        meta :meta_keep => "More meta than you"
        meta :meta_drop => "Way more meta than you"
      end
    end

    shared_examples "surviving metadata" do
      specify { expect(subject).to have_keys(:type, :length, :meta_keep) }
      specify { expect(subject).not_to have_key(:meta_drop) }
    end


    context "can be non-destructively dropped" do
      subject(:id_derived) { id.drop_meta :meta_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively dropped" do
      before { id.drop_meta! :meta_drop }
      it_behaves_like "surviving metadata"
    end

    context "can be non-destructively kept" do
      subject(:id_derived) { id.keep_meta :length, :meta_keep }
      it_behaves_like "surviving metadata"
    end

    context "can be destructively kept" do
      before { id.keep_meta! :length, :meta_keep }
      it_behaves_like "surviving metadata"
    end
  end
end
