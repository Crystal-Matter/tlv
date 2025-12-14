require "./spec_helper"

# Test classes for failure scenarios
class ExpectsUInt32
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : UInt32
end

class ExpectsString
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property name : String
end

class ExpectsArray
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property items : Array(UInt8)
end

class ExpectsBool
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property flag : Bool
end

class ExpectsNested
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property inner : ExpectsUInt32
end

class RequiredField
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property required : UInt32

  @[TLV::Field(tag: 2)]
  property also_required : String
end

class ExpectsBytes
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property data : Bytes
end

class ExpectsFloat
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : Float32
end

describe "TLV Deserialization Failures" do
  describe "type mismatches" do
    it "raises when expecting UInt32 but got String" do
      # Encode a string where UInt32 is expected
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 1, String "hello"
        0x18,                                           # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsUInt32.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsUInt32")
      ex.message.to_s.should contain("value")
      ex.message.to_s.should contain("String")
      ex.message.to_s.should contain("UInt32")
    end

    it "raises when expecting String but got UInt8" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsString.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsString")
      ex.message.to_s.should contain("name")
      ex.message.to_s.should contain("UInt8")
    end

    it "raises when expecting Bool but got UInt8" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x01, # Tag 1, UInt8 1
        0x18,             # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsBool.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsBool")
      ex.message.to_s.should contain("flag")
      ex.message.to_s.should contain("UInt8")
    end

    it "raises when expecting Array but got UInt8" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsArray.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsArray")
      ex.message.to_s.should contain("items")
      ex.message.to_s.should contain("UInt8")
    end

    it "raises when expecting nested structure but got UInt8" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42 (should be structure)
        0x18,             # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsNested.from_slice(bytes)
      end
      # The error shows the nested type context: ExpectsNested.inner expected ExpectsUInt32
      # which in turn expected a Structure but got UInt8
      ex.message.to_s.should contain("ExpectsNested")
      ex.message.to_s.should contain("inner")
      # The error might show the inner type's expectation
      ex.message.to_s.should contain("UInt8")
    end

    it "raises when expecting Bytes but got String" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 1, String "hello"
        0x18,                                           # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsBytes.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsBytes")
      ex.message.to_s.should contain("data")
      ex.message.to_s.should contain("String")
    end

    it "raises when expecting Float32 but got String" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 1, String "hello"
        0x18,                                           # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsFloat.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsFloat")
      ex.message.to_s.should contain("value")
      ex.message.to_s.should contain("String")
    end
  end

  describe "missing required fields" do
    it "raises when required field is missing" do
      # Only provide tag 1, but tag 2 is also required
      bytes = Bytes[
        0x15,                               # Structure start
        0x26, 0x01, 0x2A, 0x00, 0x00, 0x00, # Tag 1, UInt32 42
        0x18,                               # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        RequiredField.from_slice(bytes)
      end
      ex.message.to_s.should contain("RequiredField")
      ex.message.to_s.should contain("also_required")
      ex.message.to_s.should contain("missing")
    end

    it "raises when all required fields are missing" do
      # Empty structure
      bytes = Bytes[
        0x15, # Structure start
        0x18, # Structure end
      ]

      ex = expect_raises(TLV::DeserializationError) do
        RequiredField.from_slice(bytes)
      end
      ex.message.to_s.should contain("RequiredField")
      ex.message.to_s.should contain("required")
      ex.message.to_s.should contain("missing")
    end
  end

  describe "structure format errors" do
    it "raises when expecting structure but got primitive" do
      # Just a UInt8 value, not wrapped in structure
      bytes = Bytes[0x04, 0x2A] # Anonymous UInt8 42

      ex = expect_raises(TLV::DeserializationError) do
        ExpectsUInt32.from_slice(bytes)
      end
      ex.message.to_s.should contain("ExpectsUInt32")
      ex.message.to_s.should contain("expected TLV Structure")
      ex.message.to_s.should contain("UInt8")
    end
  end

  describe "IO deserialization failures" do
    it "raises type mismatch when reading from IO" do
      bytes = Bytes[
        0x15,                                           # Structure start
        0x2C, 0x01, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F, # Tag 1, String "hello"
        0x18,                                           # Structure end
      ]

      io = IO::Memory.new(bytes)
      ex = expect_raises(TLV::DeserializationError) do
        io.read_bytes(ExpectsUInt32)
      end
      ex.message.to_s.should contain("ExpectsUInt32")
      ex.message.to_s.should contain("String")
    end

    it "raises missing field when reading from IO" do
      bytes = Bytes[
        0x15, # Structure start
        0x18, # Structure end
      ]

      io = IO::Memory.new(bytes)
      ex = expect_raises(TLV::DeserializationError) do
        io.read_bytes(RequiredField)
      end
      ex.message.to_s.should contain("RequiredField")
      ex.message.to_s.should contain("required")
    end
  end

  describe "TLV::Any type casting failures" do
    it "raises when casting UInt8 to String" do
      bytes = Bytes[0x04, 0x2A] # Anonymous UInt8 42
      any = TLV::Any.from_slice(bytes)

      ex = expect_raises(TypeCastError) do
        any.as_s
      end
      ex.message.to_s.should contain("UInt8")
    end

    it "raises when casting String to UInt8" do
      bytes = Bytes[0x0C, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F] # "hello"
      any = TLV::Any.from_slice(bytes)

      ex = expect_raises(TypeCastError) do
        any.as_u8
      end
      ex.message.to_s.should contain("String")
    end

    it "raises when casting Bool to UInt8" do
      bytes = Bytes[0x09] # true
      any = TLV::Any.from_slice(bytes)

      ex = expect_raises(TypeCastError) do
        any.as_u8
      end
      ex.message.to_s.should contain("Bool")
    end

    it "raises when casting Structure to String" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Structure end
      ]
      any = TLV::Any.from_slice(bytes)

      expect_raises(TypeCastError) do
        any.as_s
      end
    end

    it "raises when accessing non-existent structure tag" do
      bytes = Bytes[
        0x15,             # Structure start
        0x24, 0x01, 0x2A, # Tag 1, UInt8 42
        0x18,             # Structure end
      ]
      any = TLV::Any.from_slice(bytes)

      expect_raises(KeyError) do
        any[99_u8] # Tag 99 doesn't exist
      end
    end
  end
end
