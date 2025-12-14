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
  property enabled : Bool

  @[TLV::Field(tag: 2)]
  property active : Bool
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
      obj.enabled.should be_true
      obj.active.should be_false
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
      parsed.enabled.should be_false
      parsed.active.should be_true
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

      expect_raises(Exception, /Missing required TLV field: not_optional_field/) do
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
end
