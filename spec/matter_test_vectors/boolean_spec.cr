# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvBooleanTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

describe "TLV Boolean (matter.js test vectors)" do
  # Test vectors from matter.js TlvBooleanTest.ts
  test_vectors = {
    "true"  => {encoded: "09", decoded: true},
    "false" => {encoded: "08", decoded: false},
  }

  describe "encode" do
    test_vectors.each do |name, vector|
      it "encodes #{name}" do
        any = TLV::Any.new(vector[:decoded])
        result = any.to_slice
        result.hexstring.should eq(vector[:encoded])
      end
    end
  end

  describe "decode" do
    test_vectors.each do |name, vector|
      it "decodes #{name}" do
        bytes = vector[:encoded].hexbytes
        any = TLV::Any.from_slice(bytes)
        any.as_bool.should eq(vector[:decoded])
      end
    end
  end

  describe "round-trip" do
    test_vectors.each do |name, vector|
      it "round-trips #{name}" do
        # Decode
        bytes = vector[:encoded].hexbytes
        any = TLV::Any.from_slice(bytes)
        # Encode
        result = any.to_slice
        result.hexstring.should eq(vector[:encoded])
      end
    end
  end
end
