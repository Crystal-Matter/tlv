require "./spec_helper"

describe "Int8#to_tlv" do
  it "encodes Int8" do
    value = 42_i8
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int8?.should be_true
    parsed.as_i8.should eq(42_i8)
  end

  it "encodes negative Int8" do
    value = -100_i8
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.as_i8.should eq(-100_i8)
  end

  it "round-trips correctly" do
    original = 127_i8
    decoded = Int8.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end

describe "Int16#to_tlv" do
  it "encodes Int16 with minimum-size encoding" do
    value = 42_i16
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int8?.should be_true
    parsed.as_i16.should eq(42_i16)
  end

  it "encodes large Int16 as Int16" do
    value = 1000_i16
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int16?.should be_true
    parsed.as_i16.should eq(1000_i16)
  end

  it "encodes with fixed_size" do
    value = 42_i16
    bytes = value.to_tlv(fixed_size: true)

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int16?.should be_true
    parsed.as_i16.should eq(42_i16)
  end

  it "round-trips correctly" do
    original = -500_i16
    decoded = Int16.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end

describe "Int32#to_tlv" do
  it "encodes small Int32 with minimum-size encoding" do
    value = 42_i32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int8?.should be_true
    parsed.as_i32.should eq(42)
  end

  it "encodes medium Int32 as Int16" do
    value = 1000_i32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int16?.should be_true
    parsed.as_i32.should eq(1000)
  end

  it "encodes large Int32 as Int32" do
    value = 100000_i32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int32?.should be_true
    parsed.as_i32.should eq(100000)
  end

  it "encodes with fixed_size" do
    value = 42_i32
    bytes = value.to_tlv(fixed_size: true)

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int32?.should be_true
    parsed.as_i32.should eq(42)
  end

  it "round-trips correctly" do
    original = -1000000_i32
    decoded = Int32.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end

describe "Int64#to_tlv" do
  it "encodes small Int64 with minimum-size encoding" do
    value = 42_i64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int8?.should be_true
    parsed.as_i64.should eq(42_i64)
  end

  it "encodes large Int64 as Int64" do
    value = 10000000000_i64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int64?.should be_true
    parsed.as_i64.should eq(10000000000_i64)
  end

  it "encodes with fixed_size" do
    value = 42_i64
    bytes = value.to_tlv(fixed_size: true)

    parsed = TLV.parse(bytes)
    parsed.header.element_type.signed_int64?.should be_true
    parsed.as_i64.should eq(42_i64)
  end

  it "round-trips correctly" do
    original = Int64::MIN
    decoded = Int64.from_tlv(original.to_tlv(fixed_size: true))
    decoded.should eq(original)
  end
end

describe "UInt8#to_tlv" do
  it "encodes UInt8" do
    value = 200_u8
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int8?.should be_true
    parsed.as_u8.should eq(200_u8)
  end

  it "round-trips correctly" do
    original = 255_u8
    decoded = UInt8.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end

describe "UInt16#to_tlv" do
  it "encodes small UInt16 with minimum-size encoding" do
    value = 100_u16
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int8?.should be_true
    parsed.as_u16.should eq(100_u16)
  end

  it "encodes large UInt16 as UInt16" do
    value = 1000_u16
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int16?.should be_true
    parsed.as_u16.should eq(1000_u16)
  end

  it "encodes with fixed_size" do
    value = 100_u16
    bytes = value.to_tlv(fixed_size: true)

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int16?.should be_true
    parsed.as_u16.should eq(100_u16)
  end

  it "round-trips correctly" do
    original = 65535_u16
    decoded = UInt16.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end

describe "UInt32#to_tlv" do
  it "encodes small UInt32 with minimum-size encoding" do
    value = 100_u32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int8?.should be_true
    parsed.as_u32.should eq(100_u32)
  end

  it "encodes large UInt32 as UInt32" do
    value = 100000_u32
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int32?.should be_true
    parsed.as_u32.should eq(100000_u32)
  end

  it "encodes with fixed_size" do
    value = 100_u32
    bytes = value.to_tlv(fixed_size: true)

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int32?.should be_true
    parsed.as_u32.should eq(100_u32)
  end

  it "round-trips correctly" do
    original = UInt32::MAX
    decoded = UInt32.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end

describe "UInt64#to_tlv" do
  it "encodes small UInt64 with minimum-size encoding" do
    value = 100_u64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int8?.should be_true
    parsed.as_u64.should eq(100_u64)
  end

  it "encodes large UInt64 as UInt64" do
    value = 10000000000_u64
    bytes = value.to_tlv

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int64?.should be_true
    parsed.as_u64.should eq(10000000000_u64)
  end

  it "encodes with fixed_size" do
    value = 100_u64
    bytes = value.to_tlv(fixed_size: true)

    parsed = TLV.parse(bytes)
    parsed.header.element_type.unsigned_int64?.should be_true
    parsed.as_u64.should eq(100_u64)
  end

  it "round-trips correctly" do
    original = UInt64::MAX
    decoded = UInt64.from_tlv(original.to_tlv)
    decoded.should eq(original)
  end
end
