# Test vectors ported from matter.js
# Source: matter.js/packages/types/test/tlv/TlvArrayTest.ts
# Copyright 2022-2025 Matter.js Authors
# SPDX-License-Identifier: Apache-2.0

require "../spec_helper"

describe "TLV Array (matter.js test vectors)" do
  describe "encode" do
    it "encodes an array of strings" do
      # matter.js: schema.encode(["a", "b", "c"]) -> "160c01610c01620c016318"
      list = TLV::List.new
      list << TLV::Any.new("a")
      list << TLV::Any.new("b")
      list << TLV::Any.new("c")
      any = TLV::Any.new(list, nil, as_array: true)
      any.to_slice.hexstring.should eq("160c01610c01620c016318")
    end

    it "encodes an empty array" do
      # matter.js: Empty array -> "1618"
      list = TLV::List.new
      any = TLV::Any.new(list, nil, as_array: true)
      any.to_slice.hexstring.should eq("1618")
    end
  end

  describe "decode" do
    it "decodes an array of strings" do
      # matter.js: schema.decode(Bytes.fromHex("160c01610c01620c016318")) -> ["a", "b", "c"]
      bytes = "160c01610c01620c016318".hexbytes
      any = TLV::Any.from_slice(bytes)
      list = any.as_list
      list.size.should eq(3)
      list[0].as_s.should eq("a")
      list[1].as_s.should eq("b")
      list[2].as_s.should eq("c")
    end

    it "decodes an empty array" do
      bytes = "1618".hexbytes
      any = TLV::Any.from_slice(bytes)
      list = any.as_list
      list.size.should eq(0)
    end
  end

  describe "round-trip" do
    it "round-trips an array of strings" do
      bytes = "160c01610c01620c016318".hexbytes
      any = TLV::Any.from_slice(bytes)
      any.to_slice.hexstring.should eq("160c01610c01620c016318")
    end
  end
end
