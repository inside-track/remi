require_relative 'remi_spec'

describe Fields do

  let :base_fields do
    Fields.new(
      {
        col1: { from: :base, base: true },
        col2: { from: :base, base: true }
      }
    )
  end

  let :fields2 do

  end

  context "merging field sets" do

    context "when there is no overlap" do
      it "unions field sets" do
        other_fields = Fields.new(
          {
            col3: {},
            col4: {}
          }
        )

        merged_fields = base_fields.merge other_fields

        expect(merged_fields.keys).to eq [:col1, :col2, :col3, :col4]
      end
    end

    context "when there is overlap" do
      let :other_fields do
        Fields.new(
          {
            col2: { from: :other, other: true },
            col3: { from: :other, other: true }
          }
        )
      end

      it "unions field sets when there is overlap" do
        merged_fields = base_fields.merge other_fields
        expect(merged_fields.keys).to eq [:col1, :col2, :col3]
      end

      it "merges overlapping metadata" do
        merged_fields = base_fields.merge other_fields

        expect(merged_fields).to eq(
          {
            col1: { from: :base, base: true },
            col2: { from: :other, base: true, other: true },
            col3: { from: :other, other: true }
          }
        )
      end

      it "does not affect the original field sets" do
        merged_fields = base_fields.merge other_fields

        expect(base_fields).to eq(
          {
            col1: { from: :base, base: true },
            col2: { from: :base, base: true }
          }
        )

        expect(other_fields).to eq(
          {
            col2: { from: :other, other: true },
            col3: { from: :other, other: true }
          }
        )
      end

      context "with a prefix" do
        it "creates new fields for names that conflict" do
          merged_fields = base_fields.merge other_fields, prefix: :other_

          expect(merged_fields).to eq(
            {
              col1: { from: :base, base: true },
              col2: { from: :base, base: true },
              other_col2: { from: :other, other: true },
              col3: { from: :other, other: true }
            }
          )
        end
      end

    end
  end
end
