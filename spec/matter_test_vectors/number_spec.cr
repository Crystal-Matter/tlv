# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvNumberTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

describe "TLV Number (matter.js test vectors)" do
  describe "signed integers" do
    # Test vectors from matter.js TlvNumberTest.ts codecVectorNumeric
    signed_int_vectors = {
      "an 1 byte signed int" => {encoded: "00ff", decoded: -1_i64},
      "a 2 bytes signed int" => {encoded: "010001", decoded: 0x0100_i64},
      "a 4 bytes signed int" => {encoded: "0200000001", decoded: 0x01000000_i64},
      "a 8 bytes signed int" => {encoded: "030000000000000100", decoded: 0x01000000000000_i64},
    }

    describe "encode" do
      it "encodes an 1 byte signed int" do
        any = TLV::Any.new(-1_i8)
        any.to_slice.hexstring.should eq("00ff")
      end

      it "encodes a 2 bytes signed int" do
        any = TLV::Any.new(0x0100_i16)
        any.to_slice.hexstring.should eq("010001")
      end

      it "encodes a 4 bytes signed int" do
        any = TLV::Any.new(0x01000000_i32)
        any.to_slice.hexstring.should eq("0200000001")
      end

      it "encodes a 8 bytes signed int" do
        any = TLV::Any.new(0x01000000000000_i64)
        any.to_slice.hexstring.should eq("030000000000000100")
      end
    end

    describe "decode" do
      signed_int_vectors.each do |name, vector|
        it "decodes #{name}" do
          bytes = vector[:encoded].hexbytes
          any = TLV::Any.from_slice(bytes)
          any.as_i64.should eq(vector[:decoded])
        end
      end
    end
  end

  describe "unsigned integers" do
    # Test vectors from matter.js TlvNumberTest.ts codecVectorNumeric
    unsigned_int_vectors = {
      "an 1 byte unsigned int" => {encoded: "0401", decoded: 1_u64},
      "a 2 bytes unsigned int" => {encoded: "050001", decoded: 0x0100_u64},
      "a 4 bytes unsigned int" => {encoded: "0600000001", decoded: 0x01000000_u64},
      "a 8 bytes unsigned int" => {encoded: "070000000000000100", decoded: 0x01000000000000_u64},
    }

    describe "encode" do
      it "encodes an 1 byte unsigned int" do
        any = TLV::Any.new(1_u8)
        any.to_slice.hexstring.should eq("0401")
      end

      it "encodes a 2 bytes unsigned int" do
        any = TLV::Any.new(0x0100_u16)
        any.to_slice.hexstring.should eq("050001")
      end

      it "encodes a 4 bytes unsigned int" do
        any = TLV::Any.new(0x01000000_u32)
        any.to_slice.hexstring.should eq("0600000001")
      end

      it "encodes a 8 bytes unsigned int" do
        any = TLV::Any.new(0x01000000000000_u64)
        any.to_slice.hexstring.should eq("070000000000000100")
      end
    end

    describe "decode" do
      unsigned_int_vectors.each do |name, vector|
        it "decodes #{name}" do
          bytes = vector[:encoded].hexbytes
          any = TLV::Any.from_slice(bytes)
          any.as_u64.should eq(vector[:decoded])
        end
      end
    end
  end

  describe "floating point" do
    # Test vectors from matter.js TlvNumberTest.ts codecVectorNumber
    float_vectors = {
      "a float"  => {encoded: "0a0892cc45", decoded: 6546.25390625_f32},
      "a double" => {encoded: "0b2fdd24064192b940", decoded: 6546.254_f64},
    }

    describe "encode" do
      it "encodes a float" do
        any = TLV::Any.new(6546.25390625_f32)
        any.to_slice.hexstring.should eq("0a0892cc45")
      end

      it "encodes a double" do
        any = TLV::Any.new(6546.254_f64)
        any.to_slice.hexstring.should eq("0b2fdd24064192b940")
      end
    end

    describe "decode" do
      it "decodes a float" do
        bytes = "0a0892cc45".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_f32.should be_close(6546.25390625_f32, 0.001)
      end

      it "decodes a double" do
        bytes = "0b2fdd24064192b940".hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_f64.should be_close(6546.254_f64, 0.001)
      end
    end
  end

  describe "special decoding" do
    it "decodes a 8 bytes small value as number" do
      # From matter.js: TlvUInt32.decode(Bytes.fromHex("070100000000000000")) should equal 1
      bytes = "070100000000000000".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.as_u64.should eq(1_u64)
    end
  end
end
