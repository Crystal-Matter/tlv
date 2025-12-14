# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvVoidTest.ts and TlvNullableTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

describe "TLV Null (matter.js test vectors)" do
  describe "null value" do
    it "encodes null" do
      any = TLV::Any.new(nil)
      any.to_slice.hexstring.should eq("14")
    end

    it "decodes null" do
      bytes = "14".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.as_nil.should be_nil
    end
  end

  describe "nullable values" do
    # Test vectors from matter.js TlvNullableTest.ts
    nullable_vectors = {
      "a non-null value" => {encoded: "0c0161", decoded: "a"},
      "a null value"     => {encoded: "14", decoded: nil},
    }

    describe "encode" do
      it "encodes a non-null value" do
        any = TLV::Any.new("a")
        any.to_slice.hexstring.should eq("0c0161")
      end

      it "encodes a null value" do
        any = TLV::Any.new(nil)
        any.to_slice.hexstring.should eq("14")
      end
    end

    describe "decode" do
      it "decodes a non-null value" do
        bytes = "0c0161".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_s.should eq("a")
      end

      it "decodes a null value" do
        bytes = "14".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.header.element_type.null?.should be_true
      end
    end
  end
end
