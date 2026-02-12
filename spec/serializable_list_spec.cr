require "./spec_helper"

# Test classes for ListFormat annotation
# ListFormat makes a struct serialize as TLV List (0x17) instead of Structure (0x15)

@[TLV::ListFormat]
class SimpleList
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  @[TLV::Field(tag: 2)]
  property name : String
end

@[TLV::ListFormat]
struct ListPacket
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property sequence : UInt16

  @[TLV::Field(tag: 2)]
  property payload : Bytes
end

@[TLV::ListFormat]
class ListWithOptional
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property required_field : UInt32

  @[TLV::Field(tag: 2)]
  property optional_field : String?
end

@[TLV::ListFormat]
class ListWithDefault
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property name : String

  @[TLV::Field(tag: 2)]
  property count : UInt32 = 10_u32
end

@[TLV::ListFormat]
class ListWithBooleans
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property? enabled : Bool

  @[TLV::Field(tag: 2)]
  property? active : Bool
end

# Regular struct (not ListFormat) for testing nested combinations
class RegularStruct
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : UInt32

  @[TLV::Field(tag: 2)]
  property label : String
end

# ListFormat containing a regular struct
@[TLV::ListFormat]
class ListWithNestedStruct
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  @[TLV::Field(tag: 2)]
  property nested : RegularStruct
end

# Regular struct containing a ListFormat struct
class StructWithNestedList
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property header : UInt32

  @[TLV::Field(tag: 2)]
  property list_data : SimpleList
end

@[TLV::ListFormat]
class ListWithArray
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property items : Array(UInt8)
end

@[TLV::ListFormat]
class ListWithTuple
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property data : Tuple(UInt8, String, UInt16)
end

@[TLV::ListFormat]
class ListWithForcedArray
  include TLV::Serializable

  # Tuple serialized as TLV Array instead of List
  @[TLV::Field(tag: 1, container: :array)]
  property items : Tuple(UInt8, UInt8, UInt8)
end

@[TLV::ListFormat]
class ListWithForcedList
  include TLV::Serializable

  # Array serialized as TLV List instead of Array
  @[TLV::Field(tag: 1, container: :list)]
  property items : Array(UInt8)
end

@[TLV::ListFormat]
class ListWithFloats
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property float32_val : Float32

  @[TLV::Field(tag: 2)]
  property float64_val : Float64
end

@[TLV::ListFormat]
class ListWithSignedInts
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property int8_val : Int8

  @[TLV::Field(tag: 2)]
  property int16_val : Int16

  @[TLV::Field(tag: 3)]
  property int32_val : Int32
end

@[TLV::ListFormat]
class ListWithProfileTags
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property required_field : UInt32

  # Common Profile Tag
  @[TLV::Field(tag: {0x235A, 42})]
  property common : UInt32

  # Vendor Profile Tag
  @[TLV::Field(tag: {0xFFFF, 0x235A, 42})]
  property vendor : UInt32
end

describe "TLV::ListFormat annotation" do
  describe "basic serialization" do
    it "serializes a class with ListFormat as TLV List" do
      # Build TLV List manually
      bytes = Bytes[
        0x17,                                     # List start (0x17 instead of Structure 0x15)
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,       # Tag 1, UInt32 42
        0x2C, 0x02, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 2, String "Test"
        0x18,                                     # List end
      ]

      obj = SimpleList.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.name.should eq("Test")

      # Verify it serializes back as a List
      any = obj.to_tlv
      any.header.element_type.should eq(TLV::ElementType::List)
    end

    it "serializes a struct with ListFormat as TLV List" do
      bytes = Bytes[
        0x17,                                     # List start
        0x25, 0x01, 0x39, 0x30,                   # Tag 1, UInt16 12345
        0x30, 0x02, 0x04, 0xDE, 0xAD, 0xBE, 0xEF, # Tag 2, Bytes
        0x18,                                     # List end
      ]

      packet = ListPacket.from_slice(bytes)
      packet.sequence.should eq(12345_u16)
      packet.payload.should eq(Bytes[0xDE, 0xAD, 0xBE, 0xEF])

      # Verify it serializes as a List
      any = packet.to_tlv
      any.header.element_type.should eq(TLV::ElementType::List)
    end

    it "round-trips a ListFormat class" do
      bytes = Bytes[
        0x17,                                           # List start
        0x26, 0x01, 0x64, 0x00, 0x00, 0x00,             # Tag 1, UInt32 100
        0x2C, 0x02, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "Hello"
        0x18,                                           # List end
      ]

      obj = SimpleList.from_slice(bytes)
      output = obj.to_slice
      parsed = SimpleList.from_slice(output)

      parsed.id.should eq(100_u32)
      parsed.name.should eq("Hello")
    end
  end

  describe "compatibility with Structure format" do
    it "deserializes ListFormat class from TLV Structure (for compatibility)" do
      # TLV Structure (0x15) should also work for ListFormat types
      bytes = Bytes[
        0x15,                                           # Structure start (not List)
        0x26, 0x01, 0xC8, 0x00, 0x00, 0x00,             # Tag 1, UInt32 200
        0x2C, 0x02, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64, # Tag 2, String "World"
        0x18,                                           # Structure end
      ]

      obj = SimpleList.from_slice(bytes)
      obj.id.should eq(200_u32)
      obj.name.should eq("World")
    end
  end

  describe "optional fields" do
    it "handles missing optional field in ListFormat" do
      bytes = Bytes[
        0x17,                               # List start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # List end
      ]

      obj = ListWithOptional.from_slice(bytes)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should be_nil
    end

    it "handles present optional field in ListFormat" do
      bytes = Bytes[
        0x17,                                           # List start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "Hello"
        0x18,                                           # List end
      ]

      obj = ListWithOptional.from_slice(bytes)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should eq("Hello")
    end

    it "omits nil optional field in ListFormat serialization" do
      bytes = Bytes[
        0x17,                               # List start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # List end
      ]

      obj = ListWithOptional.from_slice(bytes)
      output = obj.to_slice
      parsed = ListWithOptional.from_slice(output)
      parsed.optional_field.should be_nil
    end
  end

  describe "default values" do
    it "uses default when field is missing in ListFormat" do
      bytes = Bytes[
        0x17,                                     # List start
        0x2C, 0x01, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 1, String "Test"
        0x18,                                     # List end
      ]

      obj = ListWithDefault.from_slice(bytes)
      obj.name.should eq("Test")
      obj.count.should eq(10_u32) # Default value
    end

    it "uses provided value when field is present in ListFormat" do
      bytes = Bytes[
        0x17,                                     # List start
        0x2C, 0x01, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 1, String "Test"
        0x26, 0x02, 0x14, 0x00, 0x00, 0x00,       # Tag 2, UInt32 20
        0x18,                                     # List end
      ]

      obj = ListWithDefault.from_slice(bytes)
      obj.name.should eq("Test")
      obj.count.should eq(20_u32)
    end
  end

  describe "booleans" do
    it "handles boolean fields in ListFormat" do
      bytes = Bytes[
        0x17,       # List start
        0x29, 0x01, # Tag 1 = true
        0x28, 0x02, # Tag 2 = false
        0x18,       # List end
      ]

      obj = ListWithBooleans.from_slice(bytes)
      obj.enabled?.should be_true
      obj.active?.should be_false
    end

    it "round-trips booleans in ListFormat" do
      bytes = Bytes[
        0x17,       # List start
        0x28, 0x01, # Tag 1 = false
        0x29, 0x02, # Tag 2 = true
        0x18,       # List end
      ]

      obj = ListWithBooleans.from_slice(bytes)
      output = obj.to_slice
      parsed = ListWithBooleans.from_slice(output)
      parsed.enabled?.should be_false
      parsed.active?.should be_true
    end
  end

  describe "nested structures" do
    it "handles ListFormat containing a regular struct" do
      bytes = Bytes[
        0x17,                                           # List start (outer is List)
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x35, 0x02,                                     # Tag 2 = structure start (nested is Structure)
        0x26, 0x01, 0x64, 0x00, 0x00, 0x00,             # Tag 1, UInt32 100
        0x2C, 0x02, 0x05, 0x49, 0x6E, 0x6E, 0x65, 0x72, # Tag 2, String "Inner"
        0x18,                                           # Inner structure end
        0x18,                                           # List end
      ]

      obj = ListWithNestedStruct.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.nested.value.should eq(100_u32)
      obj.nested.label.should eq("Inner")

      # Verify outer is List, inner is Structure
      any = obj.to_tlv
      any.header.element_type.should eq(TLV::ElementType::List)
    end

    it "handles regular struct containing a ListFormat" do
      bytes = Bytes[
        0x15,                                           # Structure start (outer is Structure)
        0x26, 0x01, 0xC8, 0x00, 0x00, 0x00,             # Tag 1, UInt32 200
        0x37, 0x02,                                     # Tag 2 = list start (nested is List)
        0x26, 0x01, 0x0A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 10
        0x2C, 0x02, 0x05, 0x4F, 0x75, 0x74, 0x65, 0x72, # Tag 2, String "Outer"
        0x18,                                           # Inner list end
        0x18,                                           # Structure end
      ]

      obj = StructWithNestedList.from_slice(bytes)
      obj.header.should eq(200_u32)
      obj.list_data.id.should eq(10_u32)
      obj.list_data.name.should eq("Outer")

      # Verify outer is Structure, inner is List
      any = obj.to_tlv
      any.header.element_type.should eq(TLV::ElementType::Structure)
    end

    it "round-trips nested ListFormat and Structure" do
      bytes = Bytes[
        0x17,                                     # List start
        0x26, 0x01, 0x01, 0x00, 0x00, 0x00,       # Tag 1, UInt32 1
        0x35, 0x02,                               # Tag 2 = structure start
        0x26, 0x01, 0x02, 0x00, 0x00, 0x00,       # Tag 1, UInt32 2
        0x2C, 0x02, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 2, String "Test"
        0x18,                                     # Inner structure end
        0x18,                                     # List end
      ]

      obj = ListWithNestedStruct.from_slice(bytes)
      output = obj.to_slice
      parsed = ListWithNestedStruct.from_slice(output)

      parsed.id.should eq(1_u32)
      parsed.nested.value.should eq(2_u32)
      parsed.nested.label.should eq("Test")
    end
  end

  describe "arrays in ListFormat" do
    it "handles array field in ListFormat" do
      bytes = Bytes[
        0x17,       # List start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # List end
      ]

      obj = ListWithArray.from_slice(bytes)
      obj.items.should eq([1_u8, 2_u8, 3_u8])
    end

    it "round-trips array in ListFormat" do
      bytes = Bytes[
        0x17,       # List start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x0A, # Anonymous UInt8: 10
        0x04, 0x14, # Anonymous UInt8: 20
        0x18,       # Array end
        0x18,       # List end
      ]

      obj = ListWithArray.from_slice(bytes)
      output = obj.to_slice
      parsed = ListWithArray.from_slice(output)
      parsed.items.should eq([10_u8, 20_u8])
    end
  end

  describe "tuples in ListFormat" do
    it "handles tuple field in ListFormat" do
      bytes = Bytes[
        0x17,                                     # List start
        0x37, 0x01,                               # Tag 1 = nested list start
        0x04, 0x2A,                               # Anonymous UInt8: 42
        0x0C, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Anonymous String: "Hello"
        0x05, 0x39, 0x30,                         # Anonymous UInt16: 12345
        0x18,                                     # Nested list end
        0x18,                                     # List end
      ]

      obj = ListWithTuple.from_slice(bytes)
      obj.data[0].should eq(42_u8)
      obj.data[1].should eq("Hello")
      obj.data[2].should eq(12345_u16)
    end

    it "round-trips tuple in ListFormat" do
      bytes = Bytes[
        0x17,                               # List start
        0x37, 0x01,                         # Tag 1 = nested list start
        0x04, 0xFF,                         # Anonymous UInt8: 255
        0x0C, 0x04, 0x54, 0x65, 0x73, 0x74, # Anonymous String: "Test"
        0x05, 0xE8, 0x03,                   # Anonymous UInt16: 1000
        0x18,                               # Nested list end
        0x18,                               # List end
      ]

      obj = ListWithTuple.from_slice(bytes)
      output = obj.to_slice
      parsed = ListWithTuple.from_slice(output)

      parsed.data[0].should eq(255_u8)
      parsed.data[1].should eq("Test")
      parsed.data[2].should eq(1000_u16)
    end
  end

  describe "container annotation in ListFormat" do
    it "handles tuple with container: :array in ListFormat" do
      bytes = Bytes[
        0x17,       # List start
        0x36, 0x01, # Tag 1 = array start (forced by container: :array)
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # List end
      ]

      obj = ListWithForcedArray.from_slice(bytes)
      obj.items[0].should eq(1_u8)
      obj.items[1].should eq(2_u8)
      obj.items[2].should eq(3_u8)

      # Verify it serializes the tuple as an array
      any = obj.to_tlv
      tuple_any = any.as_list[0]
      tuple_any.header.element_type.should eq(TLV::ElementType::Array)
    end

    it "handles array with container: :list in ListFormat" do
      bytes = Bytes[
        0x17,       # List start
        0x37, 0x01, # Tag 1 = nested list start (forced by container: :list)
        0x04, 0x05, # Anonymous UInt8: 5
        0x04, 0x06, # Anonymous UInt8: 6
        0x04, 0x07, # Anonymous UInt8: 7
        0x18,       # Nested list end
        0x18,       # List end
      ]

      obj = ListWithForcedList.from_slice(bytes)
      obj.items.should eq([5_u8, 6_u8, 7_u8])

      # Verify it serializes the array as a list
      any = obj.to_tlv
      array_any = any.as_list[0]
      array_any.header.element_type.should eq(TLV::ElementType::List)
    end
  end

  describe "floating point numbers" do
    it "handles floats in ListFormat" do
      io = IO::Memory.new
      io.write_bytes(0x17_u8, IO::ByteFormat::LittleEndian) # List start

      # Float32 tag 1
      io.write_bytes(0x2A_u8, IO::ByteFormat::LittleEndian) # Context tag + Float32
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(3.14_f32, IO::ByteFormat::LittleEndian)

      # Float64 tag 2
      io.write_bytes(0x2B_u8, IO::ByteFormat::LittleEndian) # Context tag + Float64
      io.write_bytes(0x02_u8, IO::ByteFormat::LittleEndian) # Tag 2
      io.write_bytes(2.71828_f64, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # List end

      obj = ListWithFloats.from_slice(io.to_slice)
      obj.float32_val.should be_close(3.14_f32, 0.001)
      obj.float64_val.should be_close(2.71828_f64, 0.00001)
    end

    it "round-trips floats in ListFormat" do
      io = IO::Memory.new
      io.write_bytes(0x17_u8, IO::ByteFormat::LittleEndian) # List start
      io.write_bytes(0x2A_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(1.5_f32, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x2B_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x02_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(2.5_f64, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # List end

      obj = ListWithFloats.from_slice(io.to_slice)
      output = obj.to_slice
      parsed = ListWithFloats.from_slice(output)
      parsed.float32_val.should be_close(1.5_f32, 0.001)
      parsed.float64_val.should be_close(2.5_f64, 0.001)
    end
  end

  describe "signed integers" do
    it "handles signed integers in ListFormat" do
      io = IO::Memory.new
      io.write_bytes(0x17_u8, IO::ByteFormat::LittleEndian) # List start

      # Int8 tag 1
      io.write_bytes(0x20_u8, IO::ByteFormat::LittleEndian) # Context tag + SignedInt8
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(-42_i8, IO::ByteFormat::LittleEndian)

      # Int16 tag 2
      io.write_bytes(0x21_u8, IO::ByteFormat::LittleEndian) # Context tag + SignedInt16
      io.write_bytes(0x02_u8, IO::ByteFormat::LittleEndian) # Tag 2
      io.write_bytes(-1000_i16, IO::ByteFormat::LittleEndian)

      # Int32 tag 3
      io.write_bytes(0x22_u8, IO::ByteFormat::LittleEndian) # Context tag + SignedInt32
      io.write_bytes(0x03_u8, IO::ByteFormat::LittleEndian) # Tag 3
      io.write_bytes(-100000_i32, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # List end

      obj = ListWithSignedInts.from_slice(io.to_slice)
      obj.int8_val.should eq(-42_i8)
      obj.int16_val.should eq(-1000_i16)
      obj.int32_val.should eq(-100000_i32)
    end
  end

  describe "profile tags in ListFormat" do
    it "handles profile tags in ListFormat" do
      io = IO::Memory.new
      io.write_bytes(0x17_u8, IO::ByteFormat::LittleEndian) # List start

      # Context tag 1, UInt32 100
      io.write_bytes(0x26_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(100_u32, IO::ByteFormat::LittleEndian)

      # Common Profile Tag: profile_id=0x235A, tag_id=42, UInt32 200
      io.write_bytes(0x46_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(200_u32, IO::ByteFormat::LittleEndian)

      # Vendor Profile Tag: vendor=0xFFFF, profile=0x235A, tag=42, UInt32 300
      io.write_bytes(0x66_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0xFFFF_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(300_u32, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # List end

      obj = ListWithProfileTags.from_slice(io.to_slice)
      obj.required_field.should eq(100_u32)
      obj.common.should eq(200_u32)
      obj.vendor.should eq(300_u32)
    end

    it "round-trips profile tags in ListFormat" do
      io = IO::Memory.new
      io.write_bytes(0x17_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x26_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(100_u32, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x46_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(200_u32, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x66_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0xFFFF_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(300_u32, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian)

      obj = ListWithProfileTags.from_slice(io.to_slice)
      output = obj.to_slice

      parsed = ListWithProfileTags.from_slice(output)
      parsed.required_field.should eq(100_u32)
      parsed.common.should eq(200_u32)
      parsed.vendor.should eq(300_u32)
    end
  end

  describe "IO deserialization" do
    it "deserializes ListFormat from IO using read_bytes" do
      bytes = Bytes[
        0x17,                                     # List start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,       # Tag 1, UInt32 42
        0x2C, 0x02, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 2, String "Test"
        0x18,                                     # List end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(SimpleList)
      obj.id.should eq(42_u32)
      obj.name.should eq("Test")
    end

    it "round-trips through IO serialization" do
      bytes = Bytes[
        0x17,                                           # List start
        0x26, 0x01, 0x64, 0x00, 0x00, 0x00,             # Tag 1, UInt32 100
        0x2C, 0x02, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "Hello"
        0x18,                                           # List end
      ]

      io_in = IO::Memory.new(bytes)
      obj = io_in.read_bytes(SimpleList)

      # Serialize back to IO
      io_out = IO::Memory.new
      io_out.write_bytes(obj)
      io_out.rewind

      # Deserialize again
      parsed = io_out.read_bytes(SimpleList)
      parsed.id.should eq(obj.id)
      parsed.name.should eq(obj.name)
    end
  end

  describe "to_tlv method" do
    it "returns TLV::Any with List element type" do
      bytes = Bytes[
        0x17,                                     # List start
        0x26, 0x01, 0x78, 0x56, 0x34, 0x12,       # Tag 1, UInt32 0x12345678
        0x2C, 0x02, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 2, String "Test"
        0x18,                                     # List end
      ]

      obj = SimpleList.from_slice(bytes)
      any = obj.to_tlv

      any.header.element_type.should eq(TLV::ElementType::List)
    end
  end

  describe "from_tlv class method" do
    it "creates ListFormat object from TLV::Any List" do
      list = TLV::List.new
      list << TLV::Any.new(0x12345678_u32, 1_u8)
      list << TLV::Any.new("Test", 2_u8)
      any = TLV::Any.new(list)

      obj = SimpleList.from_tlv(any)
      obj.id.should eq(0x12345678_u32)
      obj.name.should eq("Test")
    end

    it "creates ListFormat object from TLV::Any Structure (compatibility)" do
      structure = TLV::Structure.new
      structure[1_u8] = TLV::Any.new(0x12345678_u32, 1_u8)
      structure[2_u8] = TLV::Any.new("Test", 2_u8)
      any = TLV::Any.new(structure)

      obj = SimpleList.from_tlv(any)
      obj.id.should eq(0x12345678_u32)
      obj.name.should eq("Test")
    end
  end
end
