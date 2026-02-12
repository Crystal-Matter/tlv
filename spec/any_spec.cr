require "./spec_helper"

describe TLV::Any do
  describe "parsing primitive types" do
    it "parses anonymous unsigned int 8-bit" do
      bytes = Bytes[0x04, 0x2A] # Anonymous UInt8 value 42
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      any.as_u8.should eq(42_u8)
    end

    it "parses anonymous unsigned int 16-bit" do
      bytes = Bytes[0x05, 0xF1, 0xFF] # Anonymous UInt16 value 65521
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      any.as_u16.should eq(65521_u16)
    end

    it "parses anonymous unsigned int 32-bit" do
      bytes = Bytes[0x06, 0x01, 0x02, 0x03, 0x04] # Anonymous UInt32 value 0x04030201
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UnsignedInt32)
      any.as_u32.should eq(0x04030201_u32)
    end

    it "parses anonymous unsigned int 64-bit" do
      bytes = Bytes[0x07, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UnsignedInt64)
      any.as_u64.should eq(0x0807060504030201_u64)
    end

    it "parses anonymous signed int 8-bit" do
      bytes = Bytes[0x00, 0xD6] # Anonymous Int8 value -42
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::SignedInt8)
      any.as_i8.should eq(-42_i8)
    end

    it "parses anonymous signed int 16-bit" do
      bytes = Bytes[0x01, 0x00, 0x80] # Anonymous Int16 value -32768
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::SignedInt16)
      any.as_i16.should eq(-32768_i16)
    end

    it "parses anonymous boolean false" do
      bytes = Bytes[0x08]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::BooleanFalse)
      any.as_bool.should be_false
    end

    it "parses anonymous boolean true" do
      bytes = Bytes[0x09]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::BooleanTrue)
      any.as_bool.should be_true
    end

    it "parses anonymous null" do
      bytes = Bytes[0x14]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Null)
      any.value.should be_nil
    end

    it "parses anonymous float32" do
      # Float32 3.14 in little-endian: C3 F5 48 40
      bytes = Bytes[0x0A, 0xC3, 0xF5, 0x48, 0x40]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Float32)
      any.as_f32.should be_close(3.14_f32, 0.001)
    end

    it "parses anonymous float64" do
      # Float64 3.14159265359 in little-endian
      bytes = Bytes[0x0B, 0xEA, 0x2E, 0x44, 0x54, 0xFB, 0x21, 0x09, 0x40]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Float64)
      any.as_f64.should be_close(3.14159265359, 0.00000001)
    end

    it "parses context-specific unsigned int 8-bit" do
      bytes = Bytes[0x24, 0x01, 0x2A] # Tag 1, UInt8 value 42
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      any.header.ids.should eq(1_u8)
      any.as_u8.should eq(42_u8)
    end
  end

  describe "parsing strings" do
    it "parses anonymous UTF-8 string with 1-byte length" do
      # "Hello" = 0x48 0x65 0x6C 0x6C 0x6F
      bytes = Bytes[0x0C, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UTF8String1)
      any.as_s.should eq("Hello")
    end

    it "parses context-specific UTF-8 string" do
      # Tag 3, "Hi" = 0x48 0x69
      bytes = Bytes[0x2C, 0x03, 0x02, 0x48, 0x69]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UTF8String1)
      any.header.ids.should eq(3_u8)
      any.as_s.should eq("Hi")
    end

    it "parses empty string" do
      bytes = Bytes[0x0C, 0x00] # Empty string
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::UTF8String1)
      any.as_s.should eq("")
    end
  end

  describe "parsing byte strings" do
    it "parses anonymous byte string with 1-byte length" do
      bytes = Bytes[0x10, 0x04, 0xDE, 0xAD, 0xBE, 0xEF]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::ByteString1)
      any.as_bytes.should eq(Bytes[0xDE, 0xAD, 0xBE, 0xEF])
    end

    it "parses empty byte string" do
      bytes = Bytes[0x10, 0x00]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::ByteString1)
      any.as_bytes.should eq(Bytes.new(0))
    end
  end

  describe "parsing structures" do
    it "parses empty structure" do
      bytes = Bytes[0x15, 0x18] # Structure start, end
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Structure)
      any.container?.should be_true
      any.size.should eq(0)
    end

    it "parses structure with single field" do
      # Structure with Tag 1 = 42 (UInt8)
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Structure end
      ]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Structure)
      any.size.should eq(1)
      any[1_u8].as_u8.should eq(42_u8)
    end

    it "parses structure with multiple fields" do
      # Structure with Tag 1 = 65521 (UInt16), Tag 2 = 32769 (UInt16)
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0xF1, 0xFF, # Tag 1, UInt16 65521
        0x25, 0x02, 0x01, 0x80, # Tag 2, UInt16 32769
        0x18,                   # Structure end
      ]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Structure)
      any.size.should eq(2)
      any[1_u8].as_u16.should eq(65521_u16)
      any[2_u8].as_u16.should eq(32769_u16)
    end

    it "parses structure with string field" do
      # Structure with Tag 3 = "Light"
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x03, 0x05, 0x4C, 0x69, 0x67, 0x68, 0x74, # Tag 3, String "Light"
        0x18,                                           # Structure end
      ]
      any = TLV::Any.from_slice(bytes)

      any.size.should eq(1)
      any[3_u8].as_s.should eq("Light")
    end

    it "parses nested structure" do
      # Outer structure with Tag 1 = inner structure containing Tag 1 = 42
      bytes = Bytes[
        0x15,             # Outer structure start
        0x35, 0x01,       # Tag 1 = structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Inner structure end
        0x18,             # Outer structure end
      ]
      any = TLV::Any.from_slice(bytes)

      any.size.should eq(1)
      inner = any[1_u8]
      inner.container?.should be_true
      inner[1_u8].as_u8.should eq(42_u8)
    end
  end

  describe "parsing arrays" do
    it "parses empty array" do
      bytes = Bytes[0x16, 0x18] # Array start, end
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Array)
      any.container?.should be_true
      any.size.should eq(0)
    end

    it "parses array of integers" do
      # Array [1, 2, 3] as UInt8
      bytes = Bytes[
        0x16,       # Array start
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
      ]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::Array)
      any.size.should eq(3)
      any[0].as_u8.should eq(1_u8)
      any[1].as_u8.should eq(2_u8)
      any[2].as_u8.should eq(3_u8)
    end

    it "parses array inside structure" do
      # Structure { Tag:1 -> Array [1, 2, 3] }
      bytes = Bytes[
        0x15,       # Structure start
        0x36, 0x01, # Tag 1 = array start
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
        0x18,       # Structure end
      ]
      any = TLV::Any.from_slice(bytes)

      any.size.should eq(1)
      arr = any[1_u8]
      arr.size.should eq(3)
      arr[0].as_u8.should eq(1_u8)
      arr[1].as_u8.should eq(2_u8)
      arr[2].as_u8.should eq(3_u8)
    end
  end

  describe "parsing lists" do
    it "parses empty list" do
      bytes = Bytes[0x17, 0x18] # List start, end
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::List)
      any.container?.should be_true
      any.size.should eq(0)
    end

    it "parses list with mixed types" do
      # List ["hello", 42, true]
      bytes = Bytes[
        0x17,                                     # List start
        0x0C, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Anonymous string "hello"
        0x04, 0x2A,                               # Anonymous UInt8: 42
        0x09,                                     # Anonymous true
        0x18,                                     # List end
      ]
      any = TLV::Any.from_slice(bytes)

      any.header.element_type.should eq(TLV::ElementType::List)
      any.size.should eq(3)
      any[0].as_s.should eq("hello")
      any[1].as_u8.should eq(42_u8)
      any[2].as_bool.should be_true
    end
  end

  describe "creating TLV::Any from values" do
    it "creates from nil" do
      any = TLV::Any.new(nil)
      any.header.element_type.should eq(TLV::ElementType::Null)
      any.value.should be_nil
    end

    it "creates from bool" do
      any_true = TLV::Any.new(true)
      any_true.header.element_type.should eq(TLV::ElementType::BooleanTrue)
      any_true.as_bool.should be_true

      any_false = TLV::Any.new(false)
      any_false.header.element_type.should eq(TLV::ElementType::BooleanFalse)
      any_false.as_bool.should be_false
    end

    it "creates from integers" do
      any = TLV::Any.new(42_u8)
      any.header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      any.as_u8.should eq(42_u8)

      any = TLV::Any.new(65521_u16)
      any.header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      any.as_u16.should eq(65521_u16)

      any = TLV::Any.new(-42_i8)
      any.header.element_type.should eq(TLV::ElementType::SignedInt8)
      any.as_i8.should eq(-42_i8)
    end

    it "creates from floats" do
      any = TLV::Any.new(3.14_f32)
      any.header.element_type.should eq(TLV::ElementType::Float32)
      any.as_f32.should be_close(3.14_f32, 0.001)

      any = TLV::Any.new(3.14159265359_f64)
      any.header.element_type.should eq(TLV::ElementType::Float64)
      any.as_f64.should be_close(3.14159265359, 0.00000001)
    end

    it "creates from string" do
      any = TLV::Any.new("Hello")
      any.header.element_type.should eq(TLV::ElementType::UTF8String1)
      any.as_s.should eq("Hello")
    end

    it "creates from bytes" do
      any = TLV::Any.new(Bytes[0xDE, 0xAD, 0xBE, 0xEF])
      any.header.element_type.should eq(TLV::ElementType::ByteString1)
      any.as_bytes.should eq(Bytes[0xDE, 0xAD, 0xBE, 0xEF])
    end

    it "creates with context tag" do
      any = TLV::Any.new(42_u8, 1_u8)
      any.header.tag_type.should eq(TLV::TagType::Context)
      any.header.ids.should eq(1_u8)
      any.as_u8.should eq(42_u8)
    end

    it "creates with common profile tag" do
      any = TLV::Any.new(42_u16, {0x235A_u16, 42_u16})
      any.header.tag_type.should eq(TLV::TagType::CommonProfile)
      ids = any.header.ids.as({UInt16, UInt16})
      ids[0].should eq(0x235A_u16)
      ids[1].should eq(42_u16)
    end

    it "creates with vendor profile tag" do
      any = TLV::Any.new(42_u32, {0xFFFF_u16, 0x235A_u16, 42_u16})
      any.header.tag_type.should eq(TLV::TagType::VendorProfile)
      ids = any.header.ids.as({UInt16, UInt16, UInt16})
      ids[0].should eq(0xFFFF_u16)
      ids[1].should eq(0x235A_u16)
      ids[2].should eq(42_u16)
    end
  end

  describe "serialization round-trip" do
    it "round-trips primitive types" do
      values = [
        TLV::Any.new(nil),
        TLV::Any.new(true),
        TLV::Any.new(false),
        TLV::Any.new(42_u8),
        TLV::Any.new(65521_u16),
        TLV::Any.new(0x12345678_u32),
        TLV::Any.new(-42_i8),
        TLV::Any.new(-32768_i16),
        TLV::Any.new(3.14_f32),
        TLV::Any.new("Hello, World!"),
        TLV::Any.new(Bytes[0xDE, 0xAD, 0xBE, 0xEF]),
      ]

      values.each do |original|
        bytes = original.to_slice
        parsed = TLV::Any.from_slice(bytes)
        parsed.header.element_type.should eq(original.header.element_type)
        parsed.value.should eq(original.value)
      end
    end

    it "round-trips structure" do
      structure = TLV::Structure.new
      structure[1_u8] = TLV::Any.new(65521_u16, 1_u8)
      structure[2_u8] = TLV::Any.new(32769_u16, 2_u8)
      structure[3_u8] = TLV::Any.new("Light", 3_u8)

      original = TLV::Any.new(structure)
      bytes = original.to_slice
      parsed = TLV::Any.from_slice(bytes)

      parsed.size.should eq(3)
      parsed[1_u8].as_u16.should eq(65521_u16)
      parsed[2_u8].as_u16.should eq(32769_u16)
      parsed[3_u8].as_s.should eq("Light")
    end

    it "round-trips array" do
      list = TLV::List.new
      list << TLV::Any.new(1_u8)
      list << TLV::Any.new(2_u8)
      list << TLV::Any.new(3_u8)

      original = TLV::Any.new(list, nil, as_array: true)
      bytes = original.to_slice
      parsed = TLV::Any.from_slice(bytes)

      parsed.size.should eq(3)
      parsed[0].as_u8.should eq(1_u8)
      parsed[1].as_u8.should eq(2_u8)
      parsed[2].as_u8.should eq(3_u8)
    end

    it "round-trips nested structure" do
      inner = TLV::Structure.new
      inner[1_u8] = TLV::Any.new(42_u8, 1_u8)

      outer = TLV::Structure.new
      outer[1_u8] = TLV::Any.new(inner, 1_u8)

      original = TLV::Any.new(outer)
      bytes = original.to_slice
      parsed = TLV::Any.from_slice(bytes)

      parsed[1_u8][1_u8].as_u8.should eq(42_u8)
    end
  end

  describe "TLV.parse" do
    it "parses bytes" do
      bytes = Bytes[0x04, 0x2A]
      any = TLV.parse(bytes)
      any.as_u8.should eq(42_u8)
    end

    it "parses from IO" do
      bytes = Bytes[0x04, 0x2A]
      io = IO::Memory.new(bytes)
      any = TLV.parse(io)
      any.as_u8.should eq(42_u8)
    end
  end

  describe "IO deserialization" do
    it "deserializes unsigned int from IO using read_bytes" do
      bytes = Bytes[0x04, 0x2A] # Anonymous UInt8 value 42
      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      any.as_u8.should eq(42_u8)
    end

    it "deserializes string from IO using read_bytes" do
      bytes = Bytes[0x0C, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F] # "Hello"
      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.header.element_type.should eq(TLV::ElementType::UTF8String1)
      any.as_s.should eq("Hello")
    end

    it "deserializes structure from IO using read_bytes" do
      bytes = Bytes[
        0x15,                   # Structure start
        0x25, 0x01, 0xF1, 0xFF, # Tag 1, UInt16 65521
        0x25, 0x02, 0x01, 0x80, # Tag 2, UInt16 32769
        0x18,                   # Structure end
      ]

      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.header.element_type.should eq(TLV::ElementType::Structure)
      any.size.should eq(2)
      any[1_u8].as_u16.should eq(65521_u16)
      any[2_u8].as_u16.should eq(32769_u16)
    end

    it "deserializes array from IO using read_bytes" do
      bytes = Bytes[
        0x16,       # Array start
        0x04, 0x01, # Anonymous UInt8: 1
        0x04, 0x02, # Anonymous UInt8: 2
        0x04, 0x03, # Anonymous UInt8: 3
        0x18,       # Array end
      ]

      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.header.element_type.should eq(TLV::ElementType::Array)
      any.size.should eq(3)
      any[0].as_u8.should eq(1_u8)
      any[1].as_u8.should eq(2_u8)
      any[2].as_u8.should eq(3_u8)
    end

    it "round-trips through IO serialization" do
      structure = TLV::Structure.new
      structure[1_u8] = TLV::Any.new(65521_u16, 1_u8)
      structure[2_u8] = TLV::Any.new(32769_u16, 2_u8)
      structure[3_u8] = TLV::Any.new("Light", 3_u8)

      original = TLV::Any.new(structure)

      # Serialize to IO
      io = IO::Memory.new
      io.write_bytes(original)
      io.rewind

      # Deserialize from IO
      parsed = io.read_bytes(TLV::Any)
      parsed.size.should eq(3)
      parsed[1_u8].as_u16.should eq(65521_u16)
      parsed[2_u8].as_u16.should eq(32769_u16)
      parsed[3_u8].as_s.should eq("Light")
    end

    it "deserializes boolean from IO using read_bytes" do
      bytes_true = Bytes[0x09]
      io_true = IO::Memory.new(bytes_true)
      any_true = io_true.read_bytes(TLV::Any)
      any_true.header.element_type.should eq(TLV::ElementType::BooleanTrue)
      any_true.as_bool.should be_true

      bytes_false = Bytes[0x08]
      io_false = IO::Memory.new(bytes_false)
      any_false = io_false.read_bytes(TLV::Any)
      any_false.header.element_type.should eq(TLV::ElementType::BooleanFalse)
      any_false.as_bool.should be_false
    end

    it "deserializes null from IO using read_bytes" do
      bytes = Bytes[0x14]
      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.header.element_type.should eq(TLV::ElementType::Null)
      any.value.should be_nil
    end

    it "deserializes byte string from IO using read_bytes" do
      bytes = Bytes[0x10, 0x04, 0xDE, 0xAD, 0xBE, 0xEF]
      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.header.element_type.should eq(TLV::ElementType::ByteString1)
      any.as_bytes.should eq(Bytes[0xDE, 0xAD, 0xBE, 0xEF])
    end

    it "deserializes nested structure from IO using read_bytes" do
      bytes = Bytes[
        0x15,             # Outer structure start
        0x35, 0x01,       # Tag 1 = structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Inner structure end
        0x18,             # Outer structure end
      ]

      io = IO::Memory.new(bytes)
      any = io.read_bytes(TLV::Any)
      any.size.should eq(1)
      inner = any[1_u8]
      inner.container?.should be_true
      inner[1_u8].as_u8.should eq(42_u8)
    end
  end

  describe "iteration" do
    it "iterates over structure entries" do
      structure = TLV::Structure.new
      structure[1_u8] = TLV::Any.new(10_u8, 1_u8)
      structure[2_u8] = TLV::Any.new(20_u8, 2_u8)

      any = TLV::Any.new(structure)
      tags = [] of TLV::TagId
      values = [] of UInt8

      any.each_pair do |tag, val|
        tags << tag
        values << val.as_u8
      end

      tags.should contain(1_u8)
      tags.should contain(2_u8)
      values.should contain(10_u8)
      values.should contain(20_u8)
    end

    it "iterates over list entries" do
      list = TLV::List.new
      list << TLV::Any.new(1_u8)
      list << TLV::Any.new(2_u8)
      list << TLV::Any.new(3_u8)

      any = TLV::Any.new(list)
      values = [] of UInt8

      any.each do |val|
        values << val.as_u8
      end

      values.should eq([1_u8, 2_u8, 3_u8])
    end
  end

  describe "nilable cast helpers" do
    it "returns nil for mismatched types instead of raising" do
      any = TLV::Any.new("hello")

      any.as_u8?.should be_nil
      any.as_bool?.should be_nil
      any.as_structure?.should be_nil
      any.as_s?.should eq("hello")
    end

    it "applies widening rules in nilable integer helpers" do
      any_u8 = TLV::Any.new(42_u8)
      any_u8.as_u16?.should eq(42_u16)
      any_u8.as_u32?.should eq(42_u32)
      any_u8.as_u64?.should eq(42_u64)

      any_i8 = TLV::Any.new(-42_i8)
      any_i8.as_i16?.should eq(-42_i16)
      any_i8.as_i32?.should eq(-42_i32)
      any_i8.as_i64?.should eq(-42_i64)
    end

    it "keeps raising helpers behavior for mismatched types" do
      any = TLV::Any.new("hello")

      expect_raises(TypeCastError) { any.as_u8 }
      expect_raises(TypeCastError) { any.as_bool }
      expect_raises(TypeCastError) { any.as_list }
    end
  end
end
