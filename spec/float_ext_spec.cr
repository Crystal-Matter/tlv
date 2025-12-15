require "./spec_helper"

describe "Float32#to_tlv" do
  it "encodes Float32" do
    value = 3.14_f32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.float32?.should be_true
    parsed.as_f32.should eq(3.14_f32)
  end

  it "encodes negative Float32" do
    value = -123.456_f32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.as_f32.should eq(-123.456_f32)
  end

  it "encodes zero" do
    value = 0.0_f32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.as_f32.should eq(0.0_f32)
  end

  it "round-trips correctly" do
    original = Float32::MAX
    decoded = Float32.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "handles special values" do
    Float32::INFINITY.to_tlv
    (-Float32::INFINITY).to_tlv
    # NaN comparison is special, just check it encodes
    Float32::NAN.to_tlv
  end
end

describe "Float64#to_tlv" do
  it "encodes Float64" do
    value = 3.14159265358979_f64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.float64?.should be_true
    parsed.as_f64.should eq(3.14159265358979_f64)
  end

  it "encodes negative Float64" do
    value = -123456.789012_f64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.as_f64.should eq(-123456.789012_f64)
  end

  it "encodes zero" do
    value = 0.0_f64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.as_f64.should eq(0.0_f64)
  end

  it "round-trips correctly" do
    original = Float64::MAX
    decoded = Float64.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end

  it "handles special values" do
    Float64::INFINITY.to_tlv
    (-Float64::INFINITY).to_tlv
    # NaN comparison is special, just check it encodes
    Float64::NAN.to_tlv
  end
end
