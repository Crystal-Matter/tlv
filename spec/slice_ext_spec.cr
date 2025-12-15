require "./spec_helper"

describe "Bytes#to_tlv" do
  it "encodes short Bytes" do
    value = Bytes[1, 2, 3, 4, 5]
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.byte_string1?.should be_true
    parsed.as_bytes.should eq(Bytes[1, 2, 3, 4, 5])
  end

  it "encodes empty Bytes" do
    value = Bytes.empty
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.byte_string1?.should be_true
    parsed.as_bytes.should eq(Bytes.empty)
  end

  it "encodes long Bytes with appropriate length prefix" do
    value = Bytes.new(300) { |i| (i % 256).to_u8 }
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.byte_string2?.should be_true
    parsed.as_bytes.should eq(value)
  end

  it "round-trips correctly" do
    original = Bytes[0, 127, 128, 255]
    decoded = Bytes.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "round-trips large Bytes" do
    original = Bytes.new(1000) { |i| (i % 256).to_u8 }
    decoded = Bytes.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "preserves binary data" do
    original = Bytes[0x00, 0x01, 0xFE, 0xFF, 0x00, 0x00]
    decoded = Bytes.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end
