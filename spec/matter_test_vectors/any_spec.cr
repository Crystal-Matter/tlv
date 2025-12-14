# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvAnyTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

describe "TLV Any (matter.js test vectors)" do
  # Test vectors from matter.js TlvAnyTest.ts
  describe "encode" do
    it "encodes null" do
      any = TLV::Any.new(nil)
      any.to_slice.hexstring.should eq("14")
    end

    it "encodes empty array" do
      list = TLV::List.new
      any = TLV::Any.new(list, nil, as_array: true)
      any.to_slice.hexstring.should eq("1618")
    end
  end

  describe "decode" do
    it "decodes null" do
      bytes = "14".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.header.element_type.null?.should be_true
    end

    it "decodes empty array" do
      bytes = "1618".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.header.element_type.array?.should be_true
      any.as_list.size.should eq(0)
    end
  end

  describe "generic decoding" do
    it "decodes a boolean" do
      bytes = "09".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.as_bool.should eq(true)
    end

    it "decodes a null" do
      bytes = "14".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.header.element_type.null?.should be_true
    end

    it "decodes an array of integers" do
      # Build: [1, 2] as TLV array
      list = TLV::List.new
      list << TLV::Any.new(1_u8)
      list << TLV::Any.new(2_u8)
      any = TLV::Any.new(list, nil, as_array: true)

      # Decode and verify
      decoded = TLV::Any.from_slice(any.to_slice)
      result = decoded.as_list
      result.size.should eq(2)
      result[0].as_u8.should eq(1_u8)
      result[1].as_u8.should eq(2_u8)
    end

    it "decodes a list of strings" do
      # Build: ["a", "b"] as TLV list
      list = TLV::List.new
      list << TLV::Any.new("a")
      list << TLV::Any.new("b")
      any = TLV::Any.new(list, nil, as_array: false)

      # Decode and verify
      decoded = TLV::Any.from_slice(any.to_slice)
      result = decoded.as_list
      result.size.should eq(2)
      result[0].as_s.should eq("a")
      result[1].as_s.should eq("b")
    end

    it "decodes a structure" do
      # Build: { 1: "a", 2: "b" } as TLV structure
      structure = TLV::Structure.new
      structure[1_u8] = TLV::Any.new("a", 1_u8)
      structure[2_u8] = TLV::Any.new("b", 2_u8)
      any = TLV::Any.new(structure)

      # Decode and verify
      decoded = TLV::Any.from_slice(any.to_slice)
      result = decoded.value.as(TLV::Structure)
      result[1_u8].as_s.should eq("a")
      result[2_u8].as_s.should eq("b")
    end

    it "decodes an array of structures" do
      # Build: [{ 1: "a", 2: "b" }, { 3: "c", 4: "d" }]
      struct1 = TLV::Structure.new
      struct1[1_u8] = TLV::Any.new("a", 1_u8)
      struct1[2_u8] = TLV::Any.new("b", 2_u8)

      struct2 = TLV::Structure.new
      struct2[3_u8] = TLV::Any.new("c", 3_u8)
      struct2[4_u8] = TLV::Any.new("d", 4_u8)

      list = TLV::List.new
      list << TLV::Any.new(struct1)
      list << TLV::Any.new(struct2)
      any = TLV::Any.new(list, nil, as_array: true)

      # Decode and verify
      decoded = TLV::Any.from_slice(any.to_slice)
      result = decoded.as_list
      result.size.should eq(2)

      s1 = result[0].value.as(TLV::Structure)
      s1[1_u8].as_s.should eq("a")
      s1[2_u8].as_s.should eq("b")

      s2 = result[1].value.as(TLV::Structure)
      s2[3_u8].as_s.should eq("c")
      s2[4_u8].as_s.should eq("d")
    end
  end
end
