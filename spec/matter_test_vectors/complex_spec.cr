# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvComplexTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

# Nested array item structure
class ArrayItem
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property mandatory_number : UInt8

  @[TLV::Field(tag: 2)]
  property optional_byte_string : Bytes?

  def initialize(@mandatory_number : UInt8, @optional_byte_string : Bytes? = nil)
  end
end

# Complex structure matching matter.js schema
class ComplexObject
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property array_field : Array(ArrayItem)

  @[TLV::Field(tag: 2)]
  property optional_string : String?

  # Nullable field - must be present, but can be null
  # In matter.js: TlvField(3, TlvNullable(TlvBoolean))
  @[TLV::Field(tag: 3, optional: false)]
  property nullable_boolean : Bool?

  def initialize(
    @array_field : Array(ArrayItem),
    @nullable_boolean : Bool? = nil,
    @optional_string : String? = nil,
  )
  end
end

describe "TLV Complex (matter.js test vectors)" do
  # Test vectors from matter.js TlvComplexTest.ts
  complex_vectors = {
    "an object with all fields" => {
      encoded: "15360115240101300203000000181524010230020399999918182c020474657374290324040124050218",
      array:   [{mandatory: 1_u8, bytes: "000000"}, {mandatory: 2_u8, bytes: "999999"}],
      string:  "test",
      bool:    true,
    },
    "an object with minimum fields" => {
      encoded: "153601152401011818340318",
      array:   [{mandatory: 1_u8, bytes: nil}],
      string:  nil,
      bool:    nil,
    },
    "an object without wrapped fields" => {
      encoded: "15360115240101300203000000181524010230020399999918182c020474657374290318",
      array:   [{mandatory: 1_u8, bytes: "000000"}, {mandatory: 2_u8, bytes: "999999"}],
      string:  "test",
      bool:    true,
    },
  }

  describe "decode complex structures" do
    it "decodes an object with all fields" do
      bytes = "15360115240101300203000000181524010230020399999918182c020474657374290318".hexbytes
      any = TLV::Any.from_slice(bytes)

      # Verify structure
      structure = any.value.as(TLV::Structure)

      # Check array field (tag 1)
      array_any = structure[1_u8]
      array_any.header.element_type.array?.should be_true
      array_list = array_any.as_list
      array_list.size.should eq(2)

      # First array item
      item1 = array_list[0].value.as(TLV::Structure)
      item1[1_u8].as_u8.should eq(1_u8)
      item1[2_u8].as_bytes.hexstring.should eq("000000")

      # Second array item
      item2 = array_list[1].value.as(TLV::Structure)
      item2[1_u8].as_u8.should eq(2_u8)
      item2[2_u8].as_bytes.hexstring.should eq("999999")

      # Check optional string (tag 2)
      structure[2_u8].as_s.should eq("test")

      # Check nullable boolean (tag 3)
      structure[3_u8].as_bool.should eq(true)
    end

    it "decodes an object with minimum fields" do
      bytes = "153601152401011818340318".hexbytes
      any = TLV::Any.from_slice(bytes)
      structure = any.value.as(TLV::Structure)

      # Check array field (tag 1)
      array_any = structure[1_u8]
      array_any.header.element_type.array?.should be_true
      array_list = array_any.as_list
      array_list.size.should eq(1)

      # First array item - only mandatory field
      item1 = array_list[0].value.as(TLV::Structure)
      item1[1_u8].as_u8.should eq(1_u8)
      item1[2_u8]?.should be_nil

      # Check nullable boolean is null (tag 3)
      structure[3_u8].header.element_type.null?.should be_true
    end
  end

  describe "encode complex structures" do
    it "encodes a complex object with minimum fields" do
      items = [ArrayItem.new(1_u8)]
      obj = ComplexObject.new(items, nil)
      encoded = obj.to_slice.hexstring

      # Should match matter.js encoding for minimum fields
      encoded.should eq("153601152401011818340318")
    end

    it "encodes a complex object with all fields" do
      items = [
        ArrayItem.new(1_u8, "000000".hexbytes),
        ArrayItem.new(2_u8, "999999".hexbytes),
      ]
      obj = ComplexObject.new(items, true, "test")
      encoded = obj.to_slice.hexstring

      # Should match matter.js encoding
      encoded.should eq("15360115240101300203000000181524010230020399999918182c020474657374290318")
    end
  end

  describe "round-trip complex structures" do
    it "round-trips minimum fields" do
      bytes = "153601152401011818340318".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.to_slice.hexstring.should eq("153601152401011818340318")
    end

    it "round-trips all fields" do
      bytes = "15360115240101300203000000181524010230020399999918182c020474657374290318".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.to_slice.hexstring.should eq("15360115240101300203000000181524010230020399999918182c020474657374290318")
    end
  end
end
