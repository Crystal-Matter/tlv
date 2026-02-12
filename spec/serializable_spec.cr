require "./spec_helper"

# Test classes for serialization
class SimpleUser
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property first_name : String

  @[TLV::Field(tag: 2)]
  property last_name : String
end

struct SimplePacket
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  @[TLV::Field(tag: 2)]
  property count : UInt16
end

class DeviceInfo
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property vendor_id : UInt16

  @[TLV::Field(tag: 2)]
  property product_id : UInt16

  @[TLV::Field(tag: 3)]
  property name : String
end

class WithOptional
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property required_field : UInt32

  @[TLV::Field(tag: 2)]
  property optional_field : String?
end

class WithDefault
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property name : String

  @[TLV::Field(tag: 2)]
  property count : UInt32 = 10_u32
end

class WithArray
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property items : Array(UInt8)
end

class WithBooleans
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property? enabled : Bool

  @[TLV::Field(tag: 2)]
  property? active : Bool
end

class WithBytes
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property data : Bytes
end

class NestedOuter
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property user : SimpleUser

  @[TLV::Field(tag: 2)]
  property count : UInt32
end

class WithFloats
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property float32_val : Float32

  @[TLV::Field(tag: 2)]
  property float64_val : Float64
end

class WithSignedInts
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property int8_val : Int8

  @[TLV::Field(tag: 2)]
  property int16_val : Int16

  @[TLV::Field(tag: 3)]
  property int32_val : Int32

  @[TLV::Field(tag: 4)]
  property int64_val : Int64
end

class WithTLVAny
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property dynamic : TLV::Any

  @[TLV::Field(tag: 2)]
  property static : UInt32
end

class WithNotOptional
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property required_field : UInt32

  @[TLV::Field(tag: 2)]
  property optional_field : String?

  # The field is not optional, but can be null
  @[TLV::Field(tag: 3, optional: false)]
  property not_optional_field : String?
end

class WithProfileTags
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

class WithTuple
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property items : Tuple(UInt8, String, UInt16)
end

class WithForcedArray
  include TLV::Serializable

  # Tuple serialized as TLV Array (homogeneous format)
  @[TLV::Field(tag: 1, container: :array)]
  property items : Tuple(UInt8, UInt8, UInt8)
end

class WithForcedList
  include TLV::Serializable

  # Array serialized as TLV List (heterogeneous format)
  @[TLV::Field(tag: 1, container: :list)]
  property items : Array(UInt8)
end

class WithUnion
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  # Union type - can be either String or UInt32
  @[TLV::Field(tag: 2)]
  property message : String | UInt32
end

class WithOptionalUnion
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  # Optional union type
  @[TLV::Field(tag: 2)]
  property data : String | UInt32 | Nil
end

class WithMultiUnion
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : UInt8 | UInt16 | UInt32 | Int8 | Int16 | Int32 | String | Bool
end

class WithFixedSize
  include TLV::Serializable

  # Without fixed_size, small values use minimum encoding
  @[TLV::Field(tag: 1)]
  property normal_u32 : UInt32

  # With fixed_size: true, always uses full 4-byte encoding
  @[TLV::Field(tag: 2, fixed_size: true)]
  property fixed_u32 : UInt32

  @[TLV::Field(tag: 3)]
  property normal_u16 : UInt16

  @[TLV::Field(tag: 4, fixed_size: true)]
  property fixed_u16 : UInt16
end

# Sized enum types for testing
enum MessageType : UInt16
  Command = 0x0100
  Inquiry = 0x0110
  Reply   = 0x0111
end

enum StatusCode : UInt8
  Success = 0x00
  Error   = 0x01
  Pending = 0x02
end

enum Priority : Int32
  Low    = -1
  Normal =  0
  High   =  1
end

class WithEnum
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property message_type : MessageType

  @[TLV::Field(tag: 2)]
  property status : StatusCode
end

class WithEnumAndData
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  @[TLV::Field(tag: 2)]
  property type : MessageType

  @[TLV::Field(tag: 3)]
  property name : String
end

class WithOptionalEnum
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt32

  @[TLV::Field(tag: 2)]
  property status : StatusCode?
end

class WithSignedEnum
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property priority : Priority
end

class WithFixedSizeEnum
  include TLV::Serializable

  # With fixed_size: true, always uses full encoding for enum's underlying type
  @[TLV::Field(tag: 1, fixed_size: true)]
  property type : MessageType
end

class WithEnumOrString
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : MessageType | String
end

describe TLV::Serializable do
  describe "basic serialization" do
    it "serializes and deserializes a simple class" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x2C, 0x01, 0x04, 0x4A, 0x6F, 0x68, 0x6E, # Tag 1, String "John"
        0x2C, 0x02, 0x03, 0x44, 0x6F, 0x65,       # Tag 2, String "Doe"
        0x18,                                     # Structure end
      ]

      user = SimpleUser.from_slice(bytes)
      user.first_name.should eq("John")
      user.last_name.should eq("Doe")
    end

    it "serializes and deserializes a struct" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x78, 0x56, 0x34, 0x12, # Tag 1, UInt32 0x12345678
        0x25, 0x02, 0x39, 0x30,             # Tag 2, UInt16 0x3039 (12345)
        0x18,                               # Structure end
      ]

      packet = SimplePacket.from_slice(bytes)
      packet.id.should eq(0x12345678_u32)
      packet.count.should eq(12345_u16)
    end

    it "round-trips DeviceInfo" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x25, 0x01, 0xF1, 0xFF,                         # Tag 1, UInt16 65521
        0x25, 0x02, 0x01, 0x80,                         # Tag 2, UInt16 32769
        0x2C, 0x03, 0x05, 0x4C, 0x69, 0x67, 0x68, 0x74, # Tag 3, String "Light"
        0x18,                                           # Structure end
      ]

      device = DeviceInfo.from_slice(bytes)
      device.vendor_id.should eq(65521_u16)
      device.product_id.should eq(32769_u16)
      device.name.should eq("Light")

      # Round-trip
      output = device.to_slice
      device2 = DeviceInfo.from_slice(output)
      device2.vendor_id.should eq(device.vendor_id)
      device2.product_id.should eq(device.product_id)
      device2.name.should eq(device.name)
    end
  end

  describe "optional fields" do
    it "handles missing optional field" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      obj = WithOptional.from_slice(bytes)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should be_nil
    end

    it "handles present optional field" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "Hello"
        0x18,                                           # Structure end
      ]

      obj = WithOptional.from_slice(bytes)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should eq("Hello")
    end

    it "omits nil optional field in serialization" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      obj = WithOptional.from_slice(bytes)
      output = obj.to_slice
      parsed = WithOptional.from_slice(output)
      parsed.optional_field.should be_nil
    end
  end

  describe "default values" do
    it "uses default when field is missing" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x2C, 0x01, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 1, String "Test"
        0x18,                                     # Structure end
      ]

      obj = WithDefault.from_slice(bytes)
      obj.name.should eq("Test")
      obj.count.should eq(10_u32) # Default value
    end

    it "uses provided value when field is present" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x2C, 0x01, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 1, String "Test"
        0x26, 0x02, 0x14, 0x00, 0x00, 0x00,       # Tag 2, UInt32 20
        0x18,                                     # Structure end
      ]

      obj = WithDefault.from_slice(bytes)
      obj.name.should eq("Test")
      obj.count.should eq(20_u32)
    end
  end

  describe "arrays" do
    it "deserializes array of integers" do
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # Structure end
      ]

      obj = WithArray.from_slice(bytes)
      obj.items.should eq([1_u8, 2_u8, 3_u8])
    end

    it "round-trips array" do
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x0A, # Anonymous UInt8: 10
        0x04, 0x14, # Anonymous UInt8: 20
        0x04, 0x1E, # Anonymous UInt8: 30
        0x18,       # Array end
        0x18,       # Structure end
      ]

      obj = WithArray.from_slice(bytes)
      output = obj.to_slice
      parsed = WithArray.from_slice(output)
      parsed.items.should eq([10_u8, 20_u8, 30_u8])
    end
  end

  describe "booleans" do
    it "handles boolean fields" do
      bytes = Bytes[
        0x15,       # Structure start
        0x29, 0x01, # Tag 1 = true
        0x28, 0x02, # Tag 2 = false
        0x18,       # Structure end
      ]

      obj = WithBooleans.from_slice(bytes)
      obj.enabled?.should be_true
      obj.active?.should be_false
    end

    it "round-trips booleans" do
      bytes = Bytes[
        0x15,       # Structure start
        0x28, 0x01, # Tag 1 = false
        0x29, 0x02, # Tag 2 = true
        0x18,       # Structure end
      ]

      obj = WithBooleans.from_slice(bytes)
      output = obj.to_slice
      parsed = WithBooleans.from_slice(output)
      parsed.enabled?.should be_false
      parsed.active?.should be_true
    end
  end

  describe "bytes" do
    it "handles byte fields" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x30, 0x01, 0x04, 0xDE, 0xAD, 0xBE, 0xEF, # Tag 1, Bytes
        0x18,                                     # Structure end
      ]

      obj = WithBytes.from_slice(bytes)
      obj.data.should eq(Bytes[0xDE, 0xAD, 0xBE, 0xEF])
    end

    it "round-trips bytes" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x30, 0x01, 0x04, 0x01, 0x02, 0x03, 0x04, # Tag 1, Bytes
        0x18,                                     # Structure end
      ]

      obj = WithBytes.from_slice(bytes)
      output = obj.to_slice
      parsed = WithBytes.from_slice(output)
      parsed.data.should eq(Bytes[0x01, 0x02, 0x03, 0x04])
    end
  end

  describe "nested structures" do
    it "deserializes nested serializable types" do
      bytes = Bytes[
        0x15,                                           # Outer structure start
        0x35, 0x01,                                     # Tag 1 = structure start (user)
        0x2C, 0x01, 0x04, 0x4A, 0x61, 0x6E, 0x65,       # Tag 1, String "Jane"
        0x2C, 0x02, 0x05, 0x53, 0x6D, 0x69, 0x74, 0x68, # Tag 2, String "Smith"
        0x18,                                           # Inner structure end
        0x26, 0x02, 0x64, 0x00, 0x00, 0x00,             # Tag 2, UInt32 100
        0x18,                                           # Outer structure end
      ]

      obj = NestedOuter.from_slice(bytes)
      obj.user.first_name.should eq("Jane")
      obj.user.last_name.should eq("Smith")
      obj.count.should eq(100_u32)
    end

    it "round-trips nested structures" do
      bytes = Bytes[
        0x15,                                           # Outer structure start
        0x35, 0x01,                                     # Tag 1 = structure start (user)
        0x2C, 0x01, 0x03, 0x42, 0x6F, 0x62,             # Tag 1, String "Bob"
        0x2C, 0x02, 0x05, 0x4A, 0x6F, 0x6E, 0x65, 0x73, # Tag 2, String "Jones"
        0x18,                                           # Inner structure end
        0x26, 0x02, 0xC8, 0x00, 0x00, 0x00,             # Tag 2, UInt32 200
        0x18,                                           # Outer structure end
      ]

      obj = NestedOuter.from_slice(bytes)
      output = obj.to_slice
      parsed = NestedOuter.from_slice(output)
      parsed.user.first_name.should eq("Bob")
      parsed.user.last_name.should eq("Jones")
      parsed.count.should eq(200_u32)
    end
  end

  describe "floating point numbers" do
    it "handles float32 and float64" do
      # Build manually since float bytes are tricky
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start

      # Float32 tag 1
      io.write_bytes(0x2A_u8, IO::ByteFormat::LittleEndian) # Context tag + Float32
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(3.14_f32, IO::ByteFormat::LittleEndian)

      # Float64 tag 2
      io.write_bytes(0x2B_u8, IO::ByteFormat::LittleEndian) # Context tag + Float64
      io.write_bytes(0x02_u8, IO::ByteFormat::LittleEndian) # Tag 2
      io.write_bytes(2.71828_f64, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithFloats.from_slice(io.to_slice)
      obj.float32_val.should be_close(3.14_f32, 0.001)
      obj.float64_val.should be_close(2.71828_f64, 0.00001)
    end

    it "round-trips floats" do
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start

      # Float32 tag 1
      io.write_bytes(0x2A_u8, IO::ByteFormat::LittleEndian) # Context tag + Float32
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(1.5_f32, IO::ByteFormat::LittleEndian)

      # Float64 tag 2
      io.write_bytes(0x2B_u8, IO::ByteFormat::LittleEndian) # Context tag + Float64
      io.write_bytes(0x02_u8, IO::ByteFormat::LittleEndian) # Tag 2
      io.write_bytes(2.5_f64, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithFloats.from_slice(io.to_slice)
      output = obj.to_slice
      parsed = WithFloats.from_slice(output)
      parsed.float32_val.should be_close(1.5_f32, 0.001)
      parsed.float64_val.should be_close(2.5_f64, 0.001)
    end
  end

  describe "signed integers" do
    it "handles signed integer types" do
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start

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

      # Int64 tag 4
      io.write_bytes(0x23_u8, IO::ByteFormat::LittleEndian) # Context tag + SignedInt64
      io.write_bytes(0x04_u8, IO::ByteFormat::LittleEndian) # Tag 4
      io.write_bytes(-10000000000_i64, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithSignedInts.from_slice(io.to_slice)
      obj.int8_val.should eq(-42_i8)
      obj.int16_val.should eq(-1000_i16)
      obj.int32_val.should eq(-100000_i32)
      obj.int64_val.should eq(-10000000000_i64)
    end
  end

  describe "TLV::Any fields" do
    it "handles TLV::Any as a field type" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x24, 0x01, 0x2A,                   # Tag 1, UInt8 42 (dynamic)
        0x26, 0x02, 0x64, 0x00, 0x00, 0x00, # Tag 2, UInt32 100 (static)
        0x18,                               # Structure end
      ]

      obj = WithTLVAny.from_slice(bytes)
      obj.dynamic.as_u8.should eq(42_u8)
      obj.static.should eq(100_u32)
    end

    it "round-trips TLV::Any fields" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 1, String "Hello" (dynamic)
        0x26, 0x02, 0xC8, 0x00, 0x00, 0x00,             # Tag 2, UInt32 200 (static)
        0x18,                                           # Structure end
      ]

      obj = WithTLVAny.from_slice(bytes)
      output = obj.to_slice
      parsed = WithTLVAny.from_slice(output)
      parsed.dynamic.as_s.should eq("Hello")
      parsed.static.should eq(200_u32)
    end
  end

  describe "to_tlv method" do
    it "returns TLV::Any from serializable" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x78, 0x56, 0x34, 0x12, # Tag 1, UInt32 0x12345678
        0x25, 0x02, 0x39, 0x30,             # Tag 2, UInt16 0x3039 (12345)
        0x18,                               # Structure end
      ]

      packet = SimplePacket.from_slice(bytes)
      any = packet.to_tlv

      any.header.element_type.should eq(TLV::ElementType::Structure)
      any[1_u8].as_u32.should eq(0x12345678_u32)
      any[2_u8].as_u16.should eq(12345_u16)
    end
  end

  describe "from_tlv class method" do
    it "creates object from TLV::Any" do
      structure = TLV::Structure.new
      structure[1_u8] = TLV::Any.new(0x12345678_u32, 1_u8)
      structure[2_u8] = TLV::Any.new(12345_u16, 2_u8)
      any = TLV::Any.new(structure)

      packet = SimplePacket.from_tlv(any)
      packet.id.should eq(0x12345678_u32)
      packet.count.should eq(12345_u16)
    end
  end

  describe "non-optional nullable fields" do
    it "handles not_optional_field with a value" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "Hello"
        0x2C, 0x03, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64, # Tag 3, String "World"
        0x18,                                           # Structure end
      ]

      obj = WithNotOptional.from_slice(bytes)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should eq("Hello")
      obj.not_optional_field.should eq("World")
    end

    it "handles not_optional_field with null value" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x34, 0x03,                         # Tag 3, Null
        0x18,                               # Structure end
      ]

      obj = WithNotOptional.from_slice(bytes)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should be_nil     # Optional field missing = nil
      obj.not_optional_field.should be_nil # Not optional but null value = nil
    end

    it "raises when not_optional_field is missing" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      expect_raises(TLV::DeserializationError, /WithNotOptional: missing required field 'not_optional_field'/) do
        WithNotOptional.from_slice(bytes)
      end
    end

    it "serializes not_optional_field even when nil" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x34, 0x03,                         # Tag 3, Null
        0x18,                               # Structure end
      ]

      obj = WithNotOptional.from_slice(bytes)
      output = obj.to_slice

      # Re-parse and verify not_optional_field is preserved (as null)
      parsed = WithNotOptional.from_slice(output)
      parsed.required_field.should eq(42_u32)
      parsed.optional_field.should be_nil
      parsed.not_optional_field.should be_nil
    end
  end

  describe "profile tags" do
    it "handles common profile tags" do
      # Build TLV with common profile tag manually
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start

      # Context tag 1, UInt32 100
      io.write_bytes(0x26_u8, IO::ByteFormat::LittleEndian) # Context + UInt32
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(100_u32, IO::ByteFormat::LittleEndian)

      # Common Profile Tag: profile_id=0x235A, tag_id=42, UInt32 200
      # Control byte: 0x46 = common profile (010) + unsigned int 32-bit (00110)
      io.write_bytes(0x46_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian) # profile_id
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)     # tag_id
      io.write_bytes(200_u32, IO::ByteFormat::LittleEndian)

      # Vendor Profile Tag: vendor=0xFFFF, profile=0x235A, tag=42, UInt32 300
      # Control byte: 0x66 = vendor profile (011) + unsigned int 32-bit (00110)
      io.write_bytes(0x66_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0xFFFF_u16, IO::ByteFormat::LittleEndian) # vendor_id
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian) # profile_id
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)     # tag_id
      io.write_bytes(300_u32, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithProfileTags.from_slice(io.to_slice)
      obj.required_field.should eq(100_u32)
      obj.common.should eq(200_u32)
      obj.vendor.should eq(300_u32)
    end

    it "round-trips profile tags" do
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start

      # Context tag 1, UInt32 100
      io.write_bytes(0x26_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(100_u32, IO::ByteFormat::LittleEndian)

      # Common Profile Tag
      io.write_bytes(0x46_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(200_u32, IO::ByteFormat::LittleEndian)

      # Vendor Profile Tag
      io.write_bytes(0x66_u8, IO::ByteFormat::LittleEndian)
      io.write_bytes(0xFFFF_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(0x235A_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(42_u16, IO::ByteFormat::LittleEndian)
      io.write_bytes(300_u32, IO::ByteFormat::LittleEndian)

      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithProfileTags.from_slice(io.to_slice)
      output = obj.to_slice

      parsed = WithProfileTags.from_slice(output)
      parsed.required_field.should eq(100_u32)
      parsed.common.should eq(200_u32)
      parsed.vendor.should eq(300_u32)
    end

    it "serializes with correct profile tag format" do
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian)
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

      obj = WithProfileTags.from_slice(io.to_slice)
      any = obj.to_tlv

      # Verify the structure contains the right tags
      any.header.element_type.should eq(TLV::ElementType::Structure)
    end
  end

  describe "tuples" do
    it "deserializes tuple from TLV list" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x37, 0x01,                               # Tag 1 = list start
        0x04, 0x2A,                               # Anonymous UInt8: 42
        0x0C, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Anonymous String: "Hello"
        0x05, 0x39, 0x30,                         # Anonymous UInt16: 12345
        0x18,                                     # List end
        0x18,                                     # Structure end
      ]

      obj = WithTuple.from_slice(bytes)
      obj.items[0].should eq(42_u8)
      obj.items[1].should eq("Hello")
      obj.items[2].should eq(12345_u16)
    end

    it "serializes tuple to TLV list" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x37, 0x01,                               # Tag 1 = list start
        0x04, 0x0A,                               # Anonymous UInt8: 10
        0x0C, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64, # Anonymous String: "World"
        0x05, 0x01, 0x00,                         # Anonymous UInt16: 1
        0x18,                                     # List end
        0x18,                                     # Structure end
      ]

      obj = WithTuple.from_slice(bytes)
      any = obj.to_tlv

      # Verify the tuple is serialized as a list (not array)
      list_any = any[1_u8]
      list_any.header.element_type.should eq(TLV::ElementType::List)
    end

    it "round-trips tuple" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x37, 0x01,                         # Tag 1 = list start
        0x04, 0xFF,                         # Anonymous UInt8: 255
        0x0C, 0x04, 0x54, 0x65, 0x73, 0x74, # Anonymous String: "Test"
        0x05, 0xE8, 0x03,                   # Anonymous UInt16: 1000
        0x18,                               # List end
        0x18,                               # Structure end
      ]

      obj = WithTuple.from_slice(bytes)
      output = obj.to_slice
      parsed = WithTuple.from_slice(output)

      parsed.items[0].should eq(255_u8)
      parsed.items[1].should eq("Test")
      parsed.items[2].should eq(1000_u16)
    end
  end

  describe "container annotation" do
    it "serializes tuple as array with container: :array" do
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start (0x36 for context + array)
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # Structure end
      ]

      obj = WithForcedArray.from_slice(bytes)
      obj.items[0].should eq(1_u8)
      obj.items[1].should eq(2_u8)
      obj.items[2].should eq(3_u8)

      # Verify it serializes back as an array
      any = obj.to_tlv
      array_any = any[1_u8]
      array_any.header.element_type.should eq(TLV::ElementType::Array)
    end

    it "round-trips tuple with container: :array" do
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x0A, # Anonymous UInt8: 10
        0x04, 0x14, # Anonymous UInt8: 20
        0x04, 0x1E, # Anonymous UInt8: 30
        0x18,       # Array end
        0x18,       # Structure end
      ]

      obj = WithForcedArray.from_slice(bytes)
      output = obj.to_slice
      parsed = WithForcedArray.from_slice(output)

      parsed.items[0].should eq(10_u8)
      parsed.items[1].should eq(20_u8)
      parsed.items[2].should eq(30_u8)
    end

    it "serializes array as list with container: :list" do
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start (input can be array)
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # Structure end
      ]

      obj = WithForcedList.from_slice(bytes)
      obj.items.should eq([1_u8, 2_u8, 3_u8])

      # Verify it serializes as a list (not array)
      any = obj.to_tlv
      list_any = any[1_u8]
      list_any.header.element_type.should eq(TLV::ElementType::List)
    end

    it "round-trips array with container: :list" do
      bytes = Bytes[
        0x15,       # Structure start
        0x37, 0x01, # Tag 1 = list start
        0x04, 0x05, # Anonymous UInt8: 5
        0x04, 0x06, # Anonymous UInt8: 6
        0x04, 0x07, # Anonymous UInt8: 7
        0x18,       # List end
        0x18,       # Structure end
      ]

      obj = WithForcedList.from_slice(bytes)
      output = obj.to_slice
      parsed = WithForcedList.from_slice(output)

      parsed.items.should eq([5_u8, 6_u8, 7_u8])
    end
  end

  describe "IO deserialization" do
    it "deserializes a simple class from IO using read_bytes" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x2C, 0x01, 0x04, 0x4A, 0x6F, 0x68, 0x6E, # Tag 1, String "John"
        0x2C, 0x02, 0x03, 0x44, 0x6F, 0x65,       # Tag 2, String "Doe"
        0x18,                                     # Structure end
      ]

      io = IO::Memory.new(bytes)
      user = io.read_bytes(SimpleUser)
      user.first_name.should eq("John")
      user.last_name.should eq("Doe")
    end

    it "deserializes a struct from IO using read_bytes" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x78, 0x56, 0x34, 0x12, # Tag 1, UInt32 0x12345678
        0x25, 0x02, 0x39, 0x30,             # Tag 2, UInt16 0x3039 (12345)
        0x18,                               # Structure end
      ]

      io = IO::Memory.new(bytes)
      packet = io.read_bytes(SimplePacket)
      packet.id.should eq(0x12345678_u32)
      packet.count.should eq(12345_u16)
    end

    it "deserializes with optional fields from IO" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "Hello"
        0x18,                                           # Structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(WithOptional)
      obj.required_field.should eq(42_u32)
      obj.optional_field.should eq("Hello")
    end

    it "deserializes nested structures from IO" do
      bytes = Bytes[
        0x15,                                           # Outer structure start
        0x35, 0x01,                                     # Tag 1 = structure start (user)
        0x2C, 0x01, 0x04, 0x4A, 0x61, 0x6E, 0x65,       # Tag 1, String "Jane"
        0x2C, 0x02, 0x05, 0x53, 0x6D, 0x69, 0x74, 0x68, # Tag 2, String "Smith"
        0x18,                                           # Inner structure end
        0x26, 0x02, 0x64, 0x00, 0x00, 0x00,             # Tag 2, UInt32 100
        0x18,                                           # Outer structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(NestedOuter)
      obj.user.first_name.should eq("Jane")
      obj.user.last_name.should eq("Smith")
      obj.count.should eq(100_u32)
    end

    it "round-trips through IO serialization" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x25, 0x01, 0xF1, 0xFF,                         # Tag 1, UInt16 65521
        0x25, 0x02, 0x01, 0x80,                         # Tag 2, UInt16 32769
        0x2C, 0x03, 0x05, 0x4C, 0x69, 0x67, 0x68, 0x74, # Tag 3, String "Light"
        0x18,                                           # Structure end
      ]

      io_in = IO::Memory.new(bytes)
      device = io_in.read_bytes(DeviceInfo)

      # Serialize back to IO
      io_out = IO::Memory.new
      io_out.write_bytes(device)
      io_out.rewind

      # Deserialize again
      device2 = io_out.read_bytes(DeviceInfo)
      device2.vendor_id.should eq(device.vendor_id)
      device2.product_id.should eq(device.product_id)
      device2.name.should eq(device.name)
    end

    it "deserializes arrays from IO" do
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # Structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(WithArray)
      obj.items.should eq([1_u8, 2_u8, 3_u8])
    end

    it "deserializes booleans from IO" do
      bytes = Bytes[
        0x15,       # Structure start
        0x29, 0x01, # Tag 1 = true
        0x28, 0x02, # Tag 2 = false
        0x18,       # Structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(WithBooleans)
      obj.enabled?.should be_true
      obj.active?.should be_false
    end

    it "deserializes tuples from IO" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x37, 0x01,                               # Tag 1 = list start
        0x04, 0x2A,                               # Anonymous UInt8: 42
        0x0C, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Anonymous String: "Hello"
        0x05, 0x39, 0x30,                         # Anonymous UInt16: 12345
        0x18,                                     # List end
        0x18,                                     # Structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(WithTuple)
      obj.items[0].should eq(42_u8)
      obj.items[1].should eq("Hello")
      obj.items[2].should eq(12345_u16)
    end
  end

  describe "union types" do
    it "deserializes union type with String value" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "hello"
        0x18,                                           # Structure end
      ]

      obj = WithUnion.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.message.should eq("hello")
      obj.message.should be_a(String)
    end

    it "deserializes union type with UInt32 value" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x26, 0x02, 0x64, 0x00, 0x00, 0x00, # Tag 2, UInt32 100
        0x18,                               # Structure end
      ]

      obj = WithUnion.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.message.should eq(100_u32)
      obj.message.should be_a(UInt32)
    end

    it "round-trips union type with String value" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "hello"
        0x18,                                           # Structure end
      ]

      obj = WithUnion.from_slice(bytes)
      output = obj.to_slice
      parsed = WithUnion.from_slice(output)
      parsed.id.should eq(42_u32)
      parsed.message.should eq("hello")
    end

    it "round-trips union type with UInt32 value" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x26, 0x02, 0x64, 0x00, 0x00, 0x00, # Tag 2, UInt32 100
        0x18,                               # Structure end
      ]

      obj = WithUnion.from_slice(bytes)
      output = obj.to_slice
      parsed = WithUnion.from_slice(output)
      parsed.id.should eq(42_u32)
      parsed.message.should eq(100_u32)
    end

    it "handles optional union with String value" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,       # Tag 1, UInt32 42
        0x2C, 0x02, 0x04, 0x74, 0x65, 0x73, 0x74, # Tag 2, String "test"
        0x18,                                     # Structure end
      ]

      obj = WithOptionalUnion.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.data.should eq("test")
    end

    it "handles optional union with nil value (missing field)" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      obj = WithOptionalUnion.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.data.should be_nil
    end

    it "handles optional union with explicit null" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x34, 0x02,                         # Tag 2, Null
        0x18,                               # Structure end
      ]

      obj = WithOptionalUnion.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.data.should be_nil
    end

    it "handles multi-type union with various types" do
      # Test with UInt8
      bytes_u8 = Bytes[0x15, 0x24, 0x01, 0x2A, 0x18] # Tag 1, UInt8 42
      obj_u8 = WithMultiUnion.from_slice(bytes_u8)
      obj_u8.value.should eq(42_u8)

      # Test with String
      bytes_str = Bytes[0x15, 0x2C, 0x01, 0x02, 0x68, 0x69, 0x18] # Tag 1, String "hi"
      obj_str = WithMultiUnion.from_slice(bytes_str)
      obj_str.value.should eq("hi")

      # Test with Bool true
      bytes_true = Bytes[0x15, 0x29, 0x01, 0x18] # Tag 1, true
      obj_true = WithMultiUnion.from_slice(bytes_true)
      obj_true.value.should eq(true)

      # Test with Bool false
      bytes_false = Bytes[0x15, 0x28, 0x01, 0x18] # Tag 1, false
      obj_false = WithMultiUnion.from_slice(bytes_false)
      obj_false.value.should eq(false)

      # Test with Int8 negative
      bytes_i8 = Bytes[0x15, 0x20, 0x01, 0xD6, 0x18] # Tag 1, Int8 -42
      obj_i8 = WithMultiUnion.from_slice(bytes_i8)
      obj_i8.value.should eq(-42_i8)
    end

    it "deserializes union from IO" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,             # Tag 1, UInt32 42
        0x2C, 0x02, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 2, String "hello"
        0x18,                                           # Structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(WithUnion)
      obj.id.should eq(42_u32)
      obj.message.should eq("hello")
    end
  end

  describe "fixed_size annotation" do
    it "uses minimum encoding without fixed_size" do
      # Build a WithFixedSize object with small values
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x05, # Tag 1, UInt8 5 (min encoded from UInt32)
        0x24, 0x02, 0x05, # Tag 2, UInt8 5 (we'll check it re-encodes as full)
        0x24, 0x03, 0x0A, # Tag 3, UInt8 10 (min encoded from UInt16)
        0x24, 0x04, 0x0A, # Tag 4, UInt8 10 (we'll check it re-encodes as full)
        0x18,             # Structure end
      ]

      obj = WithFixedSize.from_slice(bytes)
      obj.normal_u32.should eq(5_u32)
      obj.fixed_u32.should eq(5_u32)
      obj.normal_u16.should eq(10_u16)
      obj.fixed_u16.should eq(10_u16)

      # Serialize and check the encoding
      output = obj.to_slice

      # Parse output to verify encoding
      any = TLV::Any.from_slice(output)

      # normal_u32 (tag 1) should use minimum encoding (UInt8)
      any[1_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt8)

      # fixed_u32 (tag 2) should use full UInt32 encoding
      any[2_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt32)

      # normal_u16 (tag 3) should use minimum encoding (UInt8)
      any[3_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt8)

      # fixed_u16 (tag 4) should use full UInt16 encoding
      any[4_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt16)
    end

    it "round-trips fixed_size fields correctly" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x64, 0x00, 0x00, 0x00, # Tag 1, UInt32 100
        0x26, 0x02, 0xC8, 0x00, 0x00, 0x00, # Tag 2, UInt32 200
        0x25, 0x03, 0x2C, 0x01,             # Tag 3, UInt16 300
        0x25, 0x04, 0x90, 0x01,             # Tag 4, UInt16 400
        0x18,                               # Structure end
      ]

      obj = WithFixedSize.from_slice(bytes)
      output = obj.to_slice
      parsed = WithFixedSize.from_slice(output)

      parsed.normal_u32.should eq(100_u32)
      parsed.fixed_u32.should eq(200_u32)
      parsed.normal_u16.should eq(300_u16)
      parsed.fixed_u16.should eq(400_u16)
    end

    it "fixed_size encoding is correct byte-level" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x01, # Tag 1, UInt8 1
        0x24, 0x02, 0x01, # Tag 2, UInt8 1 (will re-encode as UInt32)
        0x24, 0x03, 0x01, # Tag 3, UInt8 1
        0x24, 0x04, 0x01, # Tag 4, UInt8 1 (will re-encode as UInt16)
        0x18,             # Structure end
      ]

      obj = WithFixedSize.from_slice(bytes)
      output = obj.to_slice

      # Expected: tag 2 should be 5 bytes (control + tag + 4 value bytes)
      # Expected: tag 4 should be 4 bytes (control + tag + 2 value bytes)
      # Let's verify the fixed_u32 (tag 2) is encoded as UInt32
      # Control byte for context tag + UInt32 = 0x26
      # Tag = 0x02
      # Value = 0x01 0x00 0x00 0x00

      # Find tag 2 in output - it should be encoded as UInt32
      # Structure: 0x15, then fields, then 0x18
      io = IO::Memory.new(output)
      any = TLV::Any.from_io(io)

      # Get the raw bytes and verify tag 2 encoding
      any[2_u8].value.should eq(1_u32)
      any[2_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt32)
    end
  end

  describe "sized enum types" do
    it "deserializes UInt16 enum" do
      # MessageType::Command = 0x0100, MessageType::Reply = 0x0111
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x00, 0x01, # Tag 1, UInt16 0x0100 (Command)
        0x24, 0x02, 0x00,       # Tag 2, UInt8 0x00 (Success)
        0x18,                   # Structure end
      ]

      obj = WithEnum.from_slice(bytes)
      obj.message_type.should eq(MessageType::Command)
      obj.status.should eq(StatusCode::Success)
    end

    it "deserializes UInt8 enum" do
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x11, 0x01, # Tag 1, UInt16 0x0111 (Reply)
        0x24, 0x02, 0x01,       # Tag 2, UInt8 0x01 (Error)
        0x18,                   # Structure end
      ]

      obj = WithEnum.from_slice(bytes)
      obj.message_type.should eq(MessageType::Reply)
      obj.status.should eq(StatusCode::Error)
    end

    it "serializes enum to correct underlying type" do
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x10, 0x01, # Tag 1, UInt16 0x0110 (Inquiry)
        0x24, 0x02, 0x02,       # Tag 2, UInt8 0x02 (Pending)
        0x18,                   # Structure end
      ]

      obj = WithEnum.from_slice(bytes)
      output = obj.to_slice
      any = TLV::Any.from_slice(output)

      # MessageType should be serialized as minimum encoding (UInt16 since 0x0110 doesn't fit in UInt8)
      any[1_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      any[1_u8].as_u16.should eq(0x0110_u16)

      # StatusCode (0x02) fits in UInt8, so minimum encoding
      any[2_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      any[2_u8].as_u8.should eq(0x02_u8)
    end

    it "round-trips enum values" do
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x11, 0x01, # Tag 1, UInt16 0x0111 (Reply)
        0x24, 0x02, 0x01,       # Tag 2, UInt8 0x01 (Error)
        0x18,                   # Structure end
      ]

      obj = WithEnum.from_slice(bytes)
      output = obj.to_slice
      parsed = WithEnum.from_slice(output)

      parsed.message_type.should eq(MessageType::Reply)
      parsed.status.should eq(StatusCode::Error)
    end

    it "handles enum with other fields" do
      bytes = Bytes[
        0x15,                                     # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00,       # Tag 1, UInt32 42
        0x25, 0x02, 0x00, 0x01,                   # Tag 2, UInt16 0x0100 (Command)
        0x2C, 0x03, 0x04, 0x54, 0x65, 0x73, 0x74, # Tag 3, String "Test"
        0x18,                                     # Structure end
      ]

      obj = WithEnumAndData.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.type.should eq(MessageType::Command)
      obj.name.should eq("Test")
    end

    it "round-trips enum with other fields" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x26, 0x01, 0x64, 0x00, 0x00, 0x00,             # Tag 1, UInt32 100
        0x25, 0x02, 0x10, 0x01,                         # Tag 2, UInt16 0x0110 (Inquiry)
        0x2C, 0x03, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 3, String "Hello"
        0x18,                                           # Structure end
      ]

      obj = WithEnumAndData.from_slice(bytes)
      output = obj.to_slice
      parsed = WithEnumAndData.from_slice(output)

      parsed.id.should eq(100_u32)
      parsed.type.should eq(MessageType::Inquiry)
      parsed.name.should eq("Hello")
    end

    it "handles optional enum - present" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x24, 0x02, 0x01,                   # Tag 2, UInt8 0x01 (Error)
        0x18,                               # Structure end
      ]

      obj = WithOptionalEnum.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.status.should eq(StatusCode::Error)
    end

    it "handles optional enum - missing" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      obj = WithOptionalEnum.from_slice(bytes)
      obj.id.should eq(42_u32)
      obj.status.should be_nil
    end

    it "serializes nil optional enum correctly" do
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      obj = WithOptionalEnum.from_slice(bytes)
      output = obj.to_slice
      parsed = WithOptionalEnum.from_slice(output)

      parsed.id.should eq(42_u32)
      parsed.status.should be_nil
    end

    it "handles signed enum types" do
      # Priority::Low = -1, Priority::Normal = 0, Priority::High = 1
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start
      io.write_bytes(0x20_u8, IO::ByteFormat::LittleEndian) # Context tag + SignedInt8
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(-1_i8, IO::ByteFormat::LittleEndian)   # Value -1 (Low)
      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithSignedEnum.from_slice(io.to_slice)
      obj.priority.should eq(Priority::Low)
    end

    it "round-trips signed enum" do
      io = IO::Memory.new
      io.write_bytes(0x15_u8, IO::ByteFormat::LittleEndian) # Structure start
      io.write_bytes(0x20_u8, IO::ByteFormat::LittleEndian) # Context tag + SignedInt8
      io.write_bytes(0x01_u8, IO::ByteFormat::LittleEndian) # Tag 1
      io.write_bytes(1_i8, IO::ByteFormat::LittleEndian)    # Value 1 (High)
      io.write_bytes(0x18_u8, IO::ByteFormat::LittleEndian) # Structure end

      obj = WithSignedEnum.from_slice(io.to_slice)
      output = obj.to_slice
      parsed = WithSignedEnum.from_slice(output)

      parsed.priority.should eq(Priority::High)
    end

    it "respects fixed_size annotation for enum" do
      # Test that fixed_size: true preserves full encoding
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x01, # Tag 1, UInt8 0x01 (but will re-encode as UInt16)
        0x18,             # Structure end
      ]

      # Can't directly create WithFixedSizeEnum with value 0x01 from bytes since
      # it's not a valid MessageType, so let's use a valid value
      bytes_valid = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x00, 0x01, # Tag 1, UInt16 0x0100 (Command)
        0x18,                   # Structure end
      ]

      obj = WithFixedSizeEnum.from_slice(bytes_valid)
      output = obj.to_slice
      any = TLV::Any.from_slice(output)

      # With fixed_size: true, should always use UInt16 encoding
      any[1_u8].header.element_type.should eq(TLV::ElementType::UnsignedInt16)
    end

    it "deserializes from IO using read_bytes" do
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x10, 0x01, # Tag 1, UInt16 0x0110 (Inquiry)
        0x24, 0x02, 0x02,       # Tag 2, UInt8 0x02 (Pending)
        0x18,                   # Structure end
      ]

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(WithEnum)
      obj.message_type.should eq(MessageType::Inquiry)
      obj.status.should eq(StatusCode::Pending)
    end

    it "handles enum | string union with enum value" do
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x00, 0x01, # Tag 1, UInt16 0x0100 (Command)
        0x18,                   # Structure end
      ]

      obj = WithEnumOrString.from_slice(bytes)
      obj.value.should eq(MessageType::Command)
      obj.value.should be_a(MessageType)
    end

    it "handles enum | string union with string value" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F, # Tag 1, String "Hello"
        0x18,                                           # Structure end
      ]

      obj = WithEnumOrString.from_slice(bytes)
      obj.value.should eq("Hello")
      obj.value.should be_a(String)
    end

    it "round-trips enum | string union" do
      # Test enum round-trip
      bytes_enum = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0x10, 0x01, # Tag 1, UInt16 0x0110 (Inquiry)
        0x18,                   # Structure end
      ]

      obj1 = WithEnumOrString.from_slice(bytes_enum)
      output1 = obj1.to_slice
      parsed1 = WithEnumOrString.from_slice(output1)
      parsed1.value.should eq(MessageType::Inquiry)

      # Test string round-trip
      bytes_str = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x57, 0x6F, 0x72, 0x6C, 0x64, # Tag 1, String "World"
        0x18,                                           # Structure end
      ]

      obj2 = WithEnumOrString.from_slice(bytes_str)
      output2 = obj2.to_slice
      parsed2 = WithEnumOrString.from_slice(output2)
      parsed2.value.should eq("World")
    end
  end
end
