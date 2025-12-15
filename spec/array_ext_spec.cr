require "./spec_helper"

struct ArrayExtPoint
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property x : Int32

  @[TLV::Field(tag: 2)]
  property y : Int32

  def initialize(@x : Int32, @y : Int32)
  end
end

class ArrayExtUser
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property name : String

  @[TLV::Field(tag: 2)]
  property age : UInt8

  def initialize(@name : String, @age : UInt8)
  end
end

describe "Array#to_tlv" do
  describe "with default container (:array)" do
    it "encodes UInt8 array" do
      arr = [1_u8, 2_u8, 3_u8]
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.map(&.as_u8).should eq([1_u8, 2_u8, 3_u8])
    end

    it "encodes Int32 array with minimum-size encoding" do
      arr = [1_i32, 256_i32, 70000_i32]
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      values = parsed.as_list
      values[0].as_i32.should eq(1)
      values[1].as_i32.should eq(256)
      values[2].as_i32.should eq(70000)
    end

    it "encodes String array" do
      arr = ["hello", "world"]
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.map(&.as_s).should eq(["hello", "world"])
    end

    it "encodes Bool array" do
      arr = [true, false, true]
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.map(&.as_bool).should eq([true, false, true])
    end

    it "encodes Float64 array" do
      arr = [1.5, 2.5, 3.5]
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.map(&.as_f64).should eq([1.5, 2.5, 3.5])
    end

    it "encodes empty array" do
      arr = [] of UInt8
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.size.should eq(0)
    end

    it "encodes Bytes array" do
      arr = [Bytes[1, 2], Bytes[3, 4, 5]]
      bytes = arr.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.map(&.as_bytes).should eq([Bytes[1, 2], Bytes[3, 4, 5]])
    end
  end

  describe "with :list container" do
    it "encodes as TLV List instead of Array" do
      arr = [1_u8, 2_u8, 3_u8]
      bytes = arr.to_tlv(:list)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed.as_list.map(&.as_u8).should eq([1_u8, 2_u8, 3_u8])
    end

    it "encodes String array as List" do
      arr = ["foo", "bar"]
      bytes = arr.to_tlv(:list)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
      parsed.as_list.map(&.as_s).should eq(["foo", "bar"])
    end
  end

  describe "with TLV::Container enum" do
    it "accepts Container::Array" do
      arr = [10_u8, 20_u8]
      bytes = arr.to_tlv(TLV::Container::Array)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
    end

    it "accepts Container::List" do
      arr = [10_u8, 20_u8]
      bytes = arr.to_tlv(TLV::Container::List)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true
    end
  end

  describe "with TLV::Serializable values" do
    it "encodes array of structs" do
      points = [ArrayExtPoint.new(1, 2), ArrayExtPoint.new(3, 4)]
      bytes = points.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.size.should eq(2)

      point1 = ArrayExtPoint.from_tlv(parsed[0])
      point1.x.should eq(1)
      point1.y.should eq(2)

      point2 = ArrayExtPoint.from_tlv(parsed[1])
      point2.x.should eq(3)
      point2.y.should eq(4)
    end

    it "encodes array of classes" do
      users = [ArrayExtUser.new("Alice", 30_u8), ArrayExtUser.new("Bob", 25_u8)]
      bytes = users.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true

      user1 = ArrayExtUser.from_tlv(parsed[0])
      user1.name.should eq("Alice")
      user1.age.should eq(30_u8)

      user2 = ArrayExtUser.from_tlv(parsed[1])
      user2.name.should eq("Bob")
      user2.age.should eq(25_u8)
    end

    it "encodes array of Serializable as List" do
      points = [ArrayExtPoint.new(10, 20)]
      bytes = points.to_tlv(:list)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true

      point = ArrayExtPoint.from_tlv(parsed[0])
      point.x.should eq(10)
      point.y.should eq(20)
    end
  end

  describe "with TLV::Any values" do
    it "encodes array of TLV::Any" do
      any_values = [
        TLV::Any.new(42_u8, nil),
        TLV::Any.new("hello", nil),
        TLV::Any.new(true, nil),
      ]
      bytes = any_values.to_tlv

      parsed = TLV.parse(bytes)
      parsed.header.element_type.array?.should be_true
      parsed.as_list.size.should eq(3)

      parsed[0].as_u8.should eq(42_u8)
      parsed[1].as_s.should eq("hello")
      parsed[2].as_bool.should be_true
    end

    it "encodes array of TLV::Any as List" do
      any_values = [
        TLV::Any.new(1.5_f32, nil),
        TLV::Any.new(Bytes[1, 2, 3], nil),
      ]
      bytes = any_values.to_tlv(:list)

      parsed = TLV.parse(bytes)
      parsed.header.element_type.list?.should be_true

      parsed[0].as_f32.should eq(1.5_f32)
      parsed[1].as_bytes.should eq(Bytes[1, 2, 3])
    end

    it "encodes mixed TLV::Any with structures" do
      point = ArrayExtPoint.new(5, 10)
      any_values = [
        TLV::Any.new(100_u32, nil),
        point.to_tlv,
      ]
      bytes = any_values.to_tlv

      parsed = TLV.parse(bytes)
      parsed[0].as_u32.should eq(100_u32)

      nested_point = ArrayExtPoint.from_tlv(parsed[1])
      nested_point.x.should eq(5)
      nested_point.y.should eq(10)
    end
  end

  describe ".from_tlv" do
    it "decodes UInt8 array" do
      bytes = [1_u8, 2_u8, 3_u8].to_tlv
      arr = Array(UInt8).from_tlv(bytes)
      arr.should eq([1_u8, 2_u8, 3_u8])
    end

    it "decodes Int32 array" do
      bytes = [100_i32, 200_i32, 300_i32].to_tlv
      arr = Array(Int32).from_tlv(bytes)
      arr.should eq([100, 200, 300])
    end

    it "decodes String array" do
      bytes = ["hello", "world"].to_tlv
      arr = Array(String).from_tlv(bytes)
      arr.should eq(["hello", "world"])
    end

    it "decodes Bool array" do
      bytes = [true, false, true].to_tlv
      arr = Array(Bool).from_tlv(bytes)
      arr.should eq([true, false, true])
    end

    it "decodes Float64 array" do
      bytes = [1.5, 2.5].to_tlv
      arr = Array(Float64).from_tlv(bytes)
      arr.should eq([1.5, 2.5])
    end

    it "decodes empty array" do
      bytes = ([] of UInt8).to_tlv
      arr = Array(UInt8).from_tlv(bytes)
      arr.should be_empty
    end

    it "decodes Bytes array" do
      bytes = [Bytes[1, 2], Bytes[3, 4, 5]].to_tlv
      arr = Array(Bytes).from_tlv(bytes)
      arr.should eq([Bytes[1, 2], Bytes[3, 4, 5]])
    end

    it "decodes array of Serializable structs" do
      points = [ArrayExtPoint.new(1, 2), ArrayExtPoint.new(3, 4)]
      bytes = points.to_tlv

      arr = Array(ArrayExtPoint).from_tlv(bytes)
      arr.size.should eq(2)
      arr[0].x.should eq(1)
      arr[0].y.should eq(2)
      arr[1].x.should eq(3)
      arr[1].y.should eq(4)
    end

    it "decodes from TLV List container" do
      bytes = [10_u8, 20_u8].to_tlv(:list)
      arr = Array(UInt8).from_tlv(bytes)
      arr.should eq([10_u8, 20_u8])
    end

    it "round-trips correctly" do
      original = [1_u32, 2_u32, 3_u32, 4_u32, 5_u32]
      bytes = original.to_tlv
      decoded = Array(UInt32).from_tlv(bytes)
      decoded.should eq(original)
    end
  end
end
