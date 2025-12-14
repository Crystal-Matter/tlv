require "bindata"

module TLV
  enum TagType : UInt8
    Anonymous     = 0b000
    Context       = 0b001
    CommonProfile = 0b010
    VendorProfile = 0b011
  end

  enum ElementType : UInt8
    SignedInt8     = 0x00
    SignedInt16    = 0x01
    SignedInt32    = 0x02
    SignedInt64    = 0x03
    UnsignedInt8   = 0x04
    UnsignedInt16  = 0x05
    UnsignedInt32  = 0x06
    UnsignedInt64  = 0x07
    BooleanFalse   = 0x08
    BooleanTrue    = 0x09
    Float32        = 0x0A
    Float64        = 0x0B
    UTF8String1    = 0x0C # 1-byte length prefix
    UTF8String2    = 0x0D # 2-byte length prefix
    UTF8String4    = 0x0E # 4-byte length prefix
    UTF8String8    = 0x0F # 8-byte length prefix
    ByteString1    = 0x10 # 1-byte length prefix
    ByteString2    = 0x11 # 2-byte length prefix
    ByteString4    = 0x12 # 4-byte length prefix
    ByteString8    = 0x13 # 8-byte length prefix
    Null           = 0x14
    Structure      = 0x15
    Array          = 0x16
    List           = 0x17
    EndOfContainer = 0x18
  end

  class Header < BinData
    endian little

    # control byte
    bit_field do
      bits 3, tag_format : UInt8
      bits 5, element_type_raw : UInt8
    end

    group :context, onlyif: -> { tag_format == TagType::Context.value } do
      field tag_id : UInt8
    end

    # Common Profile - 2 bytes profile + 2 bytes tag
    group :common, onlyif: -> { tag_format == TagType::CommonProfile.value } do
      field profile_id : UInt16
      field tag_id : UInt16
    end

    # Vendor Profile - 2 bytes vendor + 2 bytes profile + 2 bytes tag
    group :vendor, onlyif: -> { tag_format >= TagType::VendorProfile.value } do
      field vendor_id : UInt16
      field profile_id : UInt16
      field tag_id : UInt16
    end

    def tag_type : TagType
      TagType.from_value?(tag_format) || TagType::VendorProfile
    end

    def element_type : ElementType
      ElementType.from_value(element_type_raw)
    end

    def element_type=(type : ElementType)
      self.element_type_raw = type.value
    end

    def tag_type=(type : TagType)
      self.tag_format = type.value
    end

    # Returns the tag identifier(s) based on tag type
    # - Anonymous: nil
    # - Context: UInt8 tag id
    # - Common Profile: {profile_id, tag_id}
    # - Vendor Profile: {vendor_id, profile_id, tag_id}
    def ids : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16}
      case tag_type
      in .anonymous?
        nil
      in .context?
        self.context.tag_id
      in .common_profile?
        {self.common.profile_id, self.common.tag_id}
      in .vendor_profile?
        {self.vendor.vendor_id, self.vendor.profile_id, self.vendor.tag_id}
      end
    end

    # Sets the tag based on various formats
    def tag=(tag : Nil)
      self.tag_type = TagType::Anonymous
    end

    def tag=(tag : UInt8)
      self.tag_type = TagType::Context
      self.context.tag_id = tag
    end

    def tag=(tag : {UInt16, UInt16})
      self.tag_type = TagType::CommonProfile
      self.common.profile_id = tag[0]
      self.common.tag_id = tag[1]
    end

    def tag=(tag : {UInt16, UInt16, UInt16})
      self.tag_type = TagType::VendorProfile
      self.vendor.vendor_id = tag[0]
      self.vendor.profile_id = tag[1]
      self.vendor.tag_id = tag[2]
    end

    def anonymous? : Bool
      tag_type.anonymous?
    end

    def container? : Bool
      element_type.structure? || element_type.array? || element_type.list?
    end

    def end_of_container? : Bool
      element_type.end_of_container?
    end

    # Creates a header with the given element type and tag
    def self.new(element_type : ElementType, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil)
      header = new
      header.element_type = element_type
      header.tag = tag
      header
    end
  end
end
