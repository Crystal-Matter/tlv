require "./spec_helper"

describe "Bool#to_tlv" do
  it "encodes true" do
    value = true
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.boolean_true?.should be_true
    parsed.as_bool.should be_true
  end

  it "encodes false" do
    value = false
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.boolean_false?.should be_true
    parsed.as_bool.should be_false
  end

  it "round-trips true correctly" do
    original = true
    decoded = Bool.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "round-trips false correctly" do
    original = false
    decoded = Bool.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "has compact encoding (1 byte)" do
    # Boolean values are encoded in the element type, no value bytes
    bytes = true.to_tlv
    bytes.size.should eq(1)

    bytes = false.to_tlv
    bytes.size.should eq(1)
  end
end
