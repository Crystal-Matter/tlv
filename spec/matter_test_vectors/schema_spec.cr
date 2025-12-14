# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvSchemaTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

# Test structures from matter.js TlvSchemaTest.ts

# Object with UInt16 and Boolean fields
class SchemaTestObject1
  include TLV::Serializable

  @[TLV::Field(tag: 2)]
  property field2 : UInt16

  @[TLV::Field(tag: 3)]
  property field3 : UInt16

  @[TLV::Field(tag: 4)]
  property field4 : Bool

  def initialize(@field2 : UInt16, @field3 : UInt16, @field4 : Bool)
  end
end

# Object with String fields
class SchemaTestObject2
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property field1 : String

  @[TLV::Field(tag: 2)]
  property field2 : String

  def initialize(@field1 : String, @field2 : String)
  end
end

# Object with Array field
class SchemaTestObject3
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property field1 : Array(String)

  def initialize(@field1 : Array(String))
  end
end

# Object with number fields
class SchemaTestObject4
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property field_float : Float32

  @[TLV::Field(tag: 2)]
  property field_double : Float64

  @[TLV::Field(tag: 3)]
  property field_int8 : Int8

  @[TLV::Field(tag: 4)]
  property field_int16 : Int16

  @[TLV::Field(tag: 5)]
  property field_int32 : Int32

  @[TLV::Field(tag: 6)]
  property field_int64 : Int64

  @[TLV::Field(tag: 7)]
  property field_uint8 : UInt8

  @[TLV::Field(tag: 8)]
  property field_uint16 : UInt16

  @[TLV::Field(tag: 9)]
  property field_uint32 : UInt32

  @[TLV::Field(tag: 10)]
  property field_uint64 : UInt64

  def initialize(
    @field_float : Float32,
    @field_double : Float64,
    @field_int8 : Int8,
    @field_int16 : Int16,
    @field_int32 : Int32,
    @field_int64 : Int64,
    @field_uint8 : UInt8,
    @field_uint16 : UInt16,
    @field_uint32 : UInt32,
    @field_uint64 : UInt64,
  )
  end
end

# Nested object
class NestedObject
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property field1 : String

  @[TLV::Field(tag: 2)]
  property field2 : String

  def initialize(@field1 : String, @field2 : String)
  end
end

# Array item struct
class ArrayStructItem
  include TLV::Serializable

  @[TLV::Field(tag: 5)]
  property field_string : String

  def initialize(@field_string : String)
  end
end

# Object with nested struct and array of struct
class SchemaTestObject5
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property field_nested1 : NestedObject

  @[TLV::Field(tag: 2)]
  property field_nested2 : NestedObject

  @[TLV::Field(tag: 3)]
  property field_array_of_structs : Array(ArrayStructItem)

  def initialize(
    @field_nested1 : NestedObject,
    @field_nested2 : NestedObject,
    @field_array_of_structs : Array(ArrayStructItem),
  )
  end
end

describe "TLV Schema (matter.js test vectors)" do
  describe "TlvObject: TlvUInt16 and TlvBoolean fields" do
    # matter.js: { field2: 1, field3: 0, field4: false } -> "15240201240300280418"
    # Uses minimum-size encoding: UInt16(1) encodes as UInt8, UInt16(0) as UInt8
    it "encodes" do
      obj = SchemaTestObject1.new(1_u16, 0_u16, false)
      obj.to_slice.hexstring.should eq("15240201240300280418")
    end

    it "decodes" do
      bytes = "15240201240300280418".hexbytes
      obj = SchemaTestObject1.from_slice(bytes)
      obj.field2.should eq(1_u16)
      obj.field3.should eq(0_u16)
      obj.field4.should eq(false)
    end
  end

  describe "TlvObject: TlvString fields" do
    # matter.js: { field1: "Hello!", field2: "Hey there, how are you?" }
    # -> "152c010648656c6c6f212c02174865792074686572652c20686f772061726520796f753f18"
    it "encodes" do
      obj = SchemaTestObject2.new("Hello!", "Hey there, how are you?")
      obj.to_slice.hexstring.should eq("152c010648656c6c6f212c02174865792074686572652c20686f772061726520796f753f18")
    end

    it "decodes" do
      bytes = "152c010648656c6c6f212c02174865792074686572652c20686f772061726520796f753f18".hexbytes
      obj = SchemaTestObject2.from_slice(bytes)
      obj.field1.should eq("Hello!")
      obj.field2.should eq("Hey there, how are you?")
    end
  end

  describe "TlvObject: TlvArray field" do
    # matter.js: { field1: ["a", "b", "c", "zzz"] }
    # -> "1536010c01610c01620c01630c037a7a7a1818"
    it "encodes" do
      obj = SchemaTestObject3.new(["a", "b", "c", "zzz"])
      obj.to_slice.hexstring.should eq("1536010c01610c01620c01630c037a7a7a1818")
    end

    it "decodes" do
      bytes = "1536010c01610c01620c01630c037a7a7a1818".hexbytes
      obj = SchemaTestObject3.from_slice(bytes)
      obj.field1.should eq(["a", "b", "c", "zzz"])
    end
  end

  describe "TlvObject: TlvNumber fields" do
    # matter.js test with all number types
    # Uses minimum-size encoding: Int16(-1) fits in Int8, Int32(-1) fits in Int8, etc.
    # -> "152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118"
    it "encodes" do
      obj = SchemaTestObject4.new(
        6546.25390625_f32,
        6546.254_f64,
        -1_i8,
        -1_i16,
        -1_i32,
        -1_i64,
        1_u8,
        1_u16,
        1_u32,
        1_u64
      )
      obj.to_slice.hexstring.should eq("152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118")
    end

    it "decodes" do
      bytes = "152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118".hexbytes
      obj = SchemaTestObject4.from_slice(bytes)
      obj.field_float.should be_close(6546.25390625_f32, 0.001)
      obj.field_double.should be_close(6546.254_f64, 0.001)
      obj.field_int8.should eq(-1_i8)
      obj.field_int16.should eq(-1_i16)
      obj.field_int32.should eq(-1_i32)
      obj.field_int64.should eq(-1_i64)
      obj.field_uint8.should eq(1_u8)
      obj.field_uint16.should eq(1_u16)
      obj.field_uint32.should eq(1_u32)
      obj.field_uint64.should eq(1_u64)
    end
  end

  describe "TlvObject: nested struct and array of struct" do
    # matter.js test with nested structures
    # -> "1535012c010574657374312c020574657374321835022c010574657374332c02057465737434183603152c0505746573743518152c0505746573743618152c05057465737437181818"
    it "encodes" do
      obj = SchemaTestObject5.new(
        NestedObject.new("test1", "test2"),
        NestedObject.new("test3", "test4"),
        [
          ArrayStructItem.new("test5"),
          ArrayStructItem.new("test6"),
          ArrayStructItem.new("test7"),
        ]
      )
      obj.to_slice.hexstring.should eq("1535012c010574657374312c020574657374321835022c010574657374332c02057465737434183603152c0505746573743518152c0505746573743618152c05057465737437181818")
    end

    it "decodes" do
      bytes = "1535012c010574657374312c020574657374321835022c010574657374332c02057465737434183603152c0505746573743518152c0505746573743618152c05057465737437181818".hexbytes
      obj = SchemaTestObject5.from_slice(bytes)
      obj.field_nested1.field1.should eq("test1")
      obj.field_nested1.field2.should eq("test2")
      obj.field_nested2.field1.should eq("test3")
      obj.field_nested2.field2.should eq("test4")
      obj.field_array_of_structs.size.should eq(3)
      obj.field_array_of_structs[0].field_string.should eq("test5")
      obj.field_array_of_structs[1].field_string.should eq("test6")
      obj.field_array_of_structs[2].field_string.should eq("test7")
    end
  end

  describe "round-trip" do
    it "round-trips UInt16 and Boolean object" do
      bytes = "15240201240300280418".hexbytes
      obj = SchemaTestObject1.from_slice(bytes)
      obj.to_slice.hexstring.should eq("15240201240300280418")
    end

    it "round-trips String object" do
      bytes = "152c010648656c6c6f212c02174865792074686572652c20686f772061726520796f753f18".hexbytes
      obj = SchemaTestObject2.from_slice(bytes)
      obj.to_slice.hexstring.should eq("152c010648656c6c6f212c02174865792074686572652c20686f772061726520796f753f18")
    end

    it "round-trips Array object" do
      bytes = "1536010c01610c01620c01630c037a7a7a1818".hexbytes
      obj = SchemaTestObject3.from_slice(bytes)
      obj.to_slice.hexstring.should eq("1536010c01610c01620c01630c037a7a7a1818")
    end

    it "round-trips Number object" do
      bytes = "152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118".hexbytes
      obj = SchemaTestObject4.from_slice(bytes)
      obj.to_slice.hexstring.should eq("152a010892cc452b022fdd24064192b9402003ff2004ff2005ff2006ff240701240801240901240a0118")
    end

    it "round-trips nested struct object" do
      bytes = "1535012c010574657374312c020574657374321835022c010574657374332c02057465737434183603152c0505746573743518152c0505746573743618152c05057465737437181818".hexbytes
      obj = SchemaTestObject5.from_slice(bytes)
      obj.to_slice.hexstring.should eq("1535012c010574657374312c020574657374321835022c010574657374332c02057465737434183603152c0505746573743518152c0505746573743618152c05057465737437181818")
    end
  end
end
