require "./spec_helper"

struct TupleExtPoint
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property x : Int32

  @[TLV::Field(tag: 2)]
  property y : Int32

  def initialize(@x : Int32, @y : Int32)
  end
end

describe "Tuple#to_tlv" do
  describe "with default container (:list)" do
    it "encodes tuple of integers" do
      tuple = {1_u8, 2_u16, 3_u32}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed.as_list.size.should eq(3)

      parsed[0].as_u8.should eq(1_u8)
      parsed[1].as_u16.should eq(2_u16)
      parsed[2].as_u32.should eq(3_u32)
    end

    it "encodes tuple of mixed types" do
      tuple = {42_u8, "hello", true, 3.14_f64}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed.as_list.size.should eq(4)

      parsed[0].as_u8.should eq(42_u8)
      parsed[1].as_s.should eq("hello")
      parsed[2].as_bool.should be_true
      parsed[3].as_f64.should eq(3.14_f64)
    end

    it "encodes tuple of strings" do
      tuple = {"foo", "bar", "baz"}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed.as_list.map(&.as_s).should eq(["foo", "bar", "baz"])
    end

    it "encodes single-element tuple" do
      tuple = {100_i32}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed.as_list.size.should eq(1)
      parsed[0].as_i32.should eq(100)
    end

    it "encodes tuple with Bytes" do
      tuple = {Bytes[1, 2, 3], Bytes[4, 5]}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed[0].as_bytes.should eq(Bytes[1, 2, 3])
      parsed[1].as_bytes.should eq(Bytes[4, 5])
    end
  end

  describe "with :array container" do
    it "encodes as TLV Array instead of List" do
      tuple = {1_u8, 2_u8, 3_u8}
      bytes = tuple.to_tlv(:array)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.map(&.as_u8).should eq([1_u8, 2_u8, 3_u8])
    end

    it "encodes mixed types as Array" do
      tuple = {"test", 123_u32}
      bytes = tuple.to_tlv(:array)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed[0].as_s.should eq("test")
      parsed[1].as_u32.should eq(123_u32)
    end
  end

  describe "with TLV::Container enum" do
    it "accepts Container::List" do
      tuple = {10_u8, 20_u8}
      bytes = tuple.to_tlv(TLV::Container::List)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
    end

    it "accepts Container::Array" do
      tuple = {10_u8, 20_u8}
      bytes = tuple.to_tlv(TLV::Container::Array)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
    end
  end

  describe "with TLV::Serializable values" do
    it "encodes tuple containing structs" do
      point = TupleExtPoint.new(5, 10)
      tuple = {point, "label"}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true

      decoded_point = TupleExtPoint.from_tlv(parsed[0])
      decoded_point.x.should eq(5)
      decoded_point.y.should eq(10)
      parsed[1].as_s.should eq("label")
    end

    it "encodes tuple of multiple structs" do
      p1 = TupleExtPoint.new(1, 2)
      p2 = TupleExtPoint.new(3, 4)
      tuple = {p1, p2}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      TupleExtPoint.from_tlv(parsed[0]).x.should eq(1)
      TupleExtPoint.from_tlv(parsed[1]).x.should eq(3)
    end
  end

  describe "with TLV::Any values" do
    it "encodes tuple of TLV::Any" do
      any_values = {
        TLV::Any.new(42_u8, nil),
        TLV::Any.new("hello", nil),
      }
      bytes = any_values.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed[0].as_u8.should eq(42_u8)
      parsed[1].as_s.should eq("hello")
    end

    it "encodes tuple mixing TLV::Any with primitives" do
      tuple = {TLV::Any.new(true, nil), 999_u32, "text"}
      bytes = tuple.to_tlv

      parsed = TLV.parse(bytes)
      parsed[0].as_bool.should be_true
      parsed[1].as_u32.should eq(999_u32)
      parsed[2].as_s.should eq("text")
    end
  end

  describe ".from_tlv" do
    it "decodes tuple of integers" do
      bytes = {1_u8, 2_u16, 3_u32}.to_tlv
      tuple = Tuple(UInt8, UInt16, UInt32).from_tlv(bytes)
      tuple.should eq({1_u8, 2_u16, 3_u32})
    end

    it "decodes tuple of mixed types" do
      bytes = {42_u8, "hello", true}.to_tlv
      tuple = Tuple(UInt8, String, Bool).from_tlv(bytes)
      tuple.should eq({42_u8, "hello", true})
    end

    it "decodes single-element tuple" do
      bytes = {100_i32}.to_tlv
      tuple = Tuple(Int32).from_tlv(bytes)
      tuple.should eq({100_i32})
    end

    it "decodes tuple with floats" do
      bytes = {1.5_f32, 2.5_f64}.to_tlv
      tuple = Tuple(Float32, Float64).from_tlv(bytes)
      tuple.should eq({1.5_f32, 2.5_f64})
    end

    it "decodes tuple with Bytes" do
      bytes = {Bytes[1, 2, 3], "test"}.to_tlv
      tuple = Tuple(Bytes, String).from_tlv(bytes)
      tuple[0].should eq(Bytes[1, 2, 3])
      tuple[1].should eq("test")
    end

    it "decodes tuple with Serializable struct" do
      point = TupleExtPoint.new(10, 20)
      bytes = {point, "label"}.to_tlv

      tuple = Tuple(TupleExtPoint, String).from_tlv(bytes)
      tuple[0].x.should eq(10)
      tuple[0].y.should eq(20)
      tuple[1].should eq("label")
    end

    it "decodes from TLV Array container" do
      bytes = {1_u8, 2_u8}.to_tlv(:array)
      tuple = Tuple(UInt8, UInt8).from_tlv(bytes)
      tuple.should eq({1_u8, 2_u8})
    end

    it "round-trips correctly" do
      original = {100_u32, "test", true, 3.14_f64}
      bytes = original.to_tlv
      decoded = Tuple(UInt32, String, Bool, Float64).from_tlv(bytes)
      decoded.should eq(original)
    end

    it "round-trips tuple of structs" do
      p1 = TupleExtPoint.new(1, 2)
      p2 = TupleExtPoint.new(3, 4)
      original = {p1, p2}
      bytes = original.to_tlv

      decoded = Tuple(TupleExtPoint, TupleExtPoint).from_tlv(bytes)
      decoded[0].x.should eq(1)
      decoded[0].y.should eq(2)
      decoded[1].x.should eq(3)
      decoded[1].y.should eq(4)
    end
  end
end
