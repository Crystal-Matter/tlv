require "./spec_helper"

describe "Nil#to_tlv" do
  it "encodes nil" do
    value = nil
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.null?.should be_true
    parsed.as_nil.should be_nil
  end

  it "round-trips correctly" do
    original = nil
    decoded = Nil.from_tlv(original.to_tlv)
    decoded.should be_nil
  end

  it "has compact encoding (1 byte)" do
    # Null values have no value bytes
    bytes = nil.to_tlv
    bytes.size.should eq(1)
  end
end
