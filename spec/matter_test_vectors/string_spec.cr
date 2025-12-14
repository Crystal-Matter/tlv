# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvStringTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

describe "TLV String (matter.js test vectors)" do
  describe "UTF-8 strings" do
    describe "encode" do
      it "encodes a string" do
        any = TLV::Any.new("test")
        any.to_slice.hexstring.should eq("0c0474657374")
      end

      it "encodes a string that gets utf8 encoded" do
        any = TLV::Any.new("testè")
        any.to_slice.hexstring.should eq("0c0674657374c3a8")
      end
    end

    describe "decode" do
      it "decodes a string" do
        bytes = "0c0474657374".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_s.should eq("test")
      end

      it "decodes a string that was utf8" do
        bytes = "0c0674657374c3a8".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_s.should eq("testè")
      end
    end
  end

  describe "byte strings" do
    describe "encode" do
      it "encodes a byte string" do
        any = TLV::Any.new("0001".hexbytes)
        any.to_slice.hexstring.should eq("10020001")
      end
    end

    describe "decode" do
      it "decodes a byte string" do
        bytes = "10020001".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_bytes.hexstring.should eq("0001")
      end
    end
  end
end
