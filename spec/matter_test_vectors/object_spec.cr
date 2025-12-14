# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvObjectTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

# Test structure matching matter.js schema:
# { mandatoryField: TlvField(1, TlvUInt8), optionalField: TlvOptionalField(2, TlvString) }
class TestObject
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property mandatory_field : UInt8

  @[TLV::Field(tag: 2)]
  property optional_field : String?

  def initialize(@mandatory_field : UInt8, @optional_field : String? = nil)
  end
end

# List-based structure for TlvTaggedList tests
class TestListObject
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property optional_field : String?

  def initialize(@optional_field : String? = nil)
  end
end

describe "TLV Object (matter.js test vectors)" do
  # Test vectors from matter.js TlvObjectTest.ts
  object_vectors = {
    "an object with all fields"         => {encoded: "152401012c02047465737418", mandatory: 1_u8, optional: "test"},
    "an object without optional fields" => {encoded: "1524010118", mandatory: 1_u8, optional: nil},
  }

  describe "encode" do
    it "encodes an object with all fields" do
      obj = TestObject.new(1_u8, "test")
      obj.to_slice.hexstring.should eq("152401012c02047465737418")
    end

    it "encodes an object without optional fields" do
      obj = TestObject.new(1_u8)
      obj.to_slice.hexstring.should eq("1524010118")
    end
  end

  describe "decode" do
    it "decodes an object with all fields" do
      bytes = "152401012c02047465737418".hexbytes
      obj = TestObject.from_slice(bytes)
      obj.mandatory_field.should eq(1_u8)
      obj.optional_field.should eq("test")
    end

    it "decodes an object without optional fields" do
      bytes = "1524010118".hexbytes
      obj = TestObject.from_slice(bytes)
      obj.mandatory_field.should eq(1_u8)
      obj.optional_field.should be_nil
    end

    it "ignores unknown fields" do
      # Decode a full object but only extract optionalField
      bytes = "152401012c02047465737418".hexbytes
      any = TLV::Any.from_slice(bytes)
      structure = any.value.as(TLV::Structure)
      structure[2_u8]?.should_not be_nil
      structure[2_u8].as_s.should eq("test")
    end
  end

  describe "round-trip" do
    object_vectors.each do |name, vector|
      it "round-trips #{name}" do
        bytes = vector[:encoded].hexbytes
        obj = TestObject.from_slice(bytes)
        obj.to_slice.hexstring.should eq(vector[:encoded])
      end
    end
  end

  describe "TlvTaggedList" do
    it "encode and decode list with optional fields" do
      # matter.js: schemaListOptional.encode({ optionalField: "test" }) -> "172c01047465737418"
      # Note: 0x17 is List start, 0x2c is context-tagged string, 0x18 is end
      # TlvTaggedList is a List (not Structure) with tagged elements
      bytes = "172c01047465737418".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.header.element_type.list?.should be_true
      list = any.as_list
      list.size.should eq(1)
      # The element has context tag 1 and value "test"
      list[0].header.ids.should eq(1_u8)
      list[0].as_s.should eq("test")
    end
  end

  describe "IO deserialization" do
    it "deserializes object with all fields from IO using read_bytes" do
      bytes = "152401012c02047465737418".hexbytes

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(TestObject)
      obj.mandatory_field.should eq(1_u8)
      obj.optional_field.should eq("test")
    end

    it "deserializes object without optional fields from IO using read_bytes" do
      bytes = "1524010118".hexbytes

      io = IO::Memory.new(bytes)
      obj = io.read_bytes(TestObject)
      obj.mandatory_field.should eq(1_u8)
      obj.optional_field.should be_nil
    end

    it "round-trips object through IO serialization" do
      bytes = "152401012c02047465737418".hexbytes

      io_in = IO::Memory.new(bytes)
      obj = io_in.read_bytes(TestObject)

      # Serialize back to IO
      io_out = IO::Memory.new
      io_out.write_bytes(obj)
      io_out.rewind

      # Deserialize again and verify
      obj2 = io_out.read_bytes(TestObject)
      obj2.mandatory_field.should eq(obj.mandatory_field)
      obj2.optional_field.should eq(obj.optional_field)
    end
  end
end
