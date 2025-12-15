require "./spec_helper"

describe "String#to_tlv" do
  it "encodes short string" do
    value = "hello"
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.utf8_string1?.should be_true
    parsed.as_s.should eq("hello")
  end

  it "encodes empty string" do
    value = ""
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.utf8_string1?.should be_true
    parsed.as_s.should eq("")
  end

  it "encodes string with unicode" do
    value = "Hello, 世界! 🌍"
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.as_s.should eq("Hello, 世界! 🌍")
  end

  it "encodes long string with appropriate length prefix" do
    value = "x" * 300
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.utf8_string2?.should be_true
    parsed.as_s.should eq("x" * 300)
  end

  it "round-trips correctly" do
    original = "The quick brown fox jumps over the lazy dog."
    decoded = String.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "preserves whitespace" do
    original = "  line1\n\tline2  \r\n"
    decoded = String.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end
