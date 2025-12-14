require "./spec_helper"

describe TLV::Header do
  describe "parsing control bytes" do
    it "parses anonymous unsigned int 8-bit" do
      # Control byte 0x04 = anonymous (000) + unsigned int 8-bit (00100)
      bytes = Bytes[0x04, 0x2A] # Anonymous UInt8 value 42
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      header.anonymous?.should be_true
      header.ids.should be_nil
    end

    it "parses context-specific tag with unsigned int 8-bit" do
      # Control byte 0x24 = context (001) + unsigned int 8-bit (00100)
      bytes = Bytes[0x24, 0x01, 0x2A] # Tag 1, UInt8 value 42
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Context)
      header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      header.anonymous?.should be_false
      header.ids.should eq(1_u8)
    end

    it "parses context-specific tag with unsigned int 16-bit" do
      # Control byte 0x25 = context (001) + unsigned int 16-bit (00101)
      bytes = Bytes[0x25, 0x01, 0xF1, 0xFF] # Tag 1, UInt16 value 65521
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Context)
      header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      header.ids.should eq(1_u8)
    end

    it "parses anonymous boolean false" do
      bytes = Bytes[0x08]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::BooleanFalse)
    end

    it "parses anonymous boolean true" do
      bytes = Bytes[0x09]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::BooleanTrue)
    end

    it "parses context-specific boolean true" do
      # Control byte 0x29 = context (001) + boolean true (01001)
      bytes = Bytes[0x29, 0x05] # Tag 5 = true
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Context)
      header.element_type.should eq(TLV::ElementType::BooleanTrue)
      header.ids.should eq(5_u8)
    end

    it "parses anonymous null" do
      bytes = Bytes[0x14]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::Null)
    end

    it "parses anonymous structure start" do
      bytes = Bytes[0x15]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::Structure)
      header.container?.should be_true
    end

    it "parses context-specific structure start" do
      # Control byte 0x35 = context (001) + structure (10101)
      bytes = Bytes[0x35, 0x01] # Tag 1 = structure
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Context)
      header.element_type.should eq(TLV::ElementType::Structure)
      header.container?.should be_true
      header.ids.should eq(1_u8)
    end

    it "parses anonymous array start" do
      bytes = Bytes[0x16]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::Array)
      header.container?.should be_true
    end

    it "parses anonymous list start" do
      bytes = Bytes[0x17]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::List)
      header.container?.should be_true
    end

    it "parses end of container" do
      bytes = Bytes[0x18]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::EndOfContainer)
      header.end_of_container?.should be_true
    end

    it "parses context-specific string with 1-byte length" do
      # Control byte 0x2C = context (001) + utf8 string 1-byte len (01100)
      bytes = Bytes[0x2C, 0x03, 0x05, 0x48, 0x65, 0x6C, 0x6C, 0x6F] # Tag 3, len 5, "Hello"
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::Context)
      header.element_type.should eq(TLV::ElementType::UTF8String1)
      header.ids.should eq(3_u8)
    end

    it "parses common profile tag" do
      # Control byte 0x45 = common profile (010) + unsigned int 16-bit (00101)
      # Profile ID: 0x235A, Tag ID: 42 (0x002A)
      bytes = Bytes[0x45, 0x5A, 0x23, 0x2A, 0x00, 0xF1, 0xFF]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::CommonProfile)
      header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      ids = header.ids.as({UInt16, UInt16})
      ids[0].should eq(0x235A_u16) # profile_id
      ids[1].should eq(42_u16)     # tag_id
    end

    it "parses vendor profile tag" do
      # Control byte 0x65 = vendor profile (011) + unsigned int 16-bit (00101)
      # Vendor ID: 0xFFFF, Profile ID: 0x235A, Tag ID: 42 (0x002A)
      bytes = Bytes[0x65, 0xFF, 0xFF, 0x5A, 0x23, 0x2A, 0x00, 0xF1, 0xFF]
      io = IO::Memory.new(bytes)
      header = TLV::Header.from_io(io)

      header.tag_type.should eq(TLV::TagType::VendorProfile)
      header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      ids = header.ids.as({UInt16, UInt16, UInt16})
      ids[0].should eq(0xFFFF_u16) # vendor_id
      ids[1].should eq(0x235A_u16) # profile_id
      ids[2].should eq(42_u16)     # tag_id
    end
  end

  describe "creating headers" do
    it "creates anonymous header" do
      header = TLV::Header.new(TLV::ElementType::UnsignedInt8, nil)
      header.tag_type.should eq(TLV::TagType::Anonymous)
      header.element_type.should eq(TLV::ElementType::UnsignedInt8)
      header.anonymous?.should be_true
    end

    it "creates context-specific header" do
      header = TLV::Header.new(TLV::ElementType::UnsignedInt16, 1_u8)
      header.tag_type.should eq(TLV::TagType::Context)
      header.element_type.should eq(TLV::ElementType::UnsignedInt16)
      header.ids.should eq(1_u8)
    end

    it "creates common profile header" do
      header = TLV::Header.new(TLV::ElementType::UnsignedInt32, {0x235A_u16, 42_u16})
      header.tag_type.should eq(TLV::TagType::CommonProfile)
      header.element_type.should eq(TLV::ElementType::UnsignedInt32)
      ids = header.ids.as({UInt16, UInt16})
      ids[0].should eq(0x235A_u16)
      ids[1].should eq(42_u16)
    end

    it "creates vendor profile header" do
      header = TLV::Header.new(TLV::ElementType::UnsignedInt64, {0xFFFF_u16, 0x235A_u16, 42_u16})
      header.tag_type.should eq(TLV::TagType::VendorProfile)
      header.element_type.should eq(TLV::ElementType::UnsignedInt64)
      ids = header.ids.as({UInt16, UInt16, UInt16})
      ids[0].should eq(0xFFFF_u16)
      ids[1].should eq(0x235A_u16)
      ids[2].should eq(42_u16)
    end
  end

  describe "serialization round-trip" do
    it "round-trips anonymous header" do
      original = TLV::Header.new(TLV::ElementType::BooleanTrue, nil)
      io = IO::Memory.new
      original.to_io(io)
      io.rewind
      parsed = TLV::Header.from_io(io)

      parsed.tag_type.should eq(original.tag_type)
      parsed.element_type.should eq(original.element_type)
    end

    it "round-trips context-specific header" do
      original = TLV::Header.new(TLV::ElementType::UTF8String1, 5_u8)
      io = IO::Memory.new
      original.to_io(io)
      io.rewind
      parsed = TLV::Header.from_io(io)

      parsed.tag_type.should eq(original.tag_type)
      parsed.element_type.should eq(original.element_type)
      parsed.ids.should eq(5_u8)
    end

    it "round-trips common profile header" do
      original = TLV::Header.new(TLV::ElementType::Float32, {0x1234_u16, 0x5678_u16})
      io = IO::Memory.new
      original.to_io(io)
      io.rewind
      parsed = TLV::Header.from_io(io)

      parsed.tag_type.should eq(original.tag_type)
      parsed.element_type.should eq(original.element_type)
      ids = parsed.ids.as({UInt16, UInt16})
      ids[0].should eq(0x1234_u16)
      ids[1].should eq(0x5678_u16)
    end

    it "round-trips vendor profile header" do
      original = TLV::Header.new(TLV::ElementType::ByteString1, {0xABCD_u16, 0x1234_u16, 0x5678_u16})
      io = IO::Memory.new
      original.to_io(io)
      io.rewind
      parsed = TLV::Header.from_io(io)

      parsed.tag_type.should eq(original.tag_type)
      parsed.element_type.should eq(original.element_type)
      ids = parsed.ids.as({UInt16, UInt16, UInt16})
      ids[0].should eq(0xABCD_u16)
      ids[1].should eq(0x1234_u16)
      ids[2].should eq(0x5678_u16)
    end
  end

  describe "element types" do
    it "detects signed integer types" do
      TLV::ElementType::SignedInt8.value.should eq(0x00)
      TLV::ElementType::SignedInt16.value.should eq(0x01)
      TLV::ElementType::SignedInt32.value.should eq(0x02)
      TLV::ElementType::SignedInt64.value.should eq(0x03)
    end

    it "detects unsigned integer types" do
      TLV::ElementType::UnsignedInt8.value.should eq(0x04)
      TLV::ElementType::UnsignedInt16.value.should eq(0x05)
      TLV::ElementType::UnsignedInt32.value.should eq(0x06)
      TLV::ElementType::UnsignedInt64.value.should eq(0x07)
    end

    it "detects boolean types" do
      TLV::ElementType::BooleanFalse.value.should eq(0x08)
      TLV::ElementType::BooleanTrue.value.should eq(0x09)
    end

    it "detects floating point types" do
      TLV::ElementType::Float32.value.should eq(0x0A)
      TLV::ElementType::Float64.value.should eq(0x0B)
    end

    it "detects string types" do
      TLV::ElementType::UTF8String1.value.should eq(0x0C)
      TLV::ElementType::UTF8String2.value.should eq(0x0D)
      TLV::ElementType::UTF8String4.value.should eq(0x0E)
      TLV::ElementType::UTF8String8.value.should eq(0x0F)
    end

    it "detects byte string types" do
      TLV::ElementType::ByteString1.value.should eq(0x10)
      TLV::ElementType::ByteString2.value.should eq(0x11)
      TLV::ElementType::ByteString4.value.should eq(0x12)
      TLV::ElementType::ByteString8.value.should eq(0x13)
    end

    it "detects container and special types" do
      TLV::ElementType::Null.value.should eq(0x14)
      TLV::ElementType::Structure.value.should eq(0x15)
      TLV::ElementType::Array.value.should eq(0x16)
      TLV::ElementType::List.value.should eq(0x17)
      TLV::ElementType::EndOfContainer.value.should eq(0x18)
    end
  end
end
