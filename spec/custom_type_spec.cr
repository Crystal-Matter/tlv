require "./spec_helper"

# A value type that is a bare integer on the wire, registered with the codec the
# way a library wrapping an identifier would do it. `TLV::Serializable` cannot be
# included, because a type that includes it encodes as a structure.
struct NodeId
  getter id : UInt64

  def initialize(@id : UInt64)
  end

  def_equals_and_hash id

  def to_tlv(outer_tag : TLV::TagId? = nil) : TLV::Any
    TLV::Any.new(@id, outer_tag)
  end

  def self.from_tlv(any : TLV::Any) : NodeId
    new(TLV::Serializable.deserialize_value(any, UInt64))
  end
end

module TLV::Serializable
  def self.serialize_value(value : NodeId, tag, fixed_size : Bool = false) : TLV::Any
    value.to_tlv(tag)
  end

  def self.deserialize_value(any : TLV::Any, type : NodeId.class) : NodeId
    type.from_tlv(any)
  end
end

# A type with no registered overloads at all.
struct Unregistered
  def initialize(@whatever : Int32)
  end
end

class CustomHolder
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property node : NodeId

  def initialize(@node : NodeId)
  end
end

class OptionalCustomHolder
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property node : NodeId?

  @[TLV::Field(tag: 2)]
  property label : String

  def initialize(@node : NodeId?, @label : String)
  end
end

class MixedUnionHolder
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : NodeId | String | Nil

  def initialize(@value : NodeId | String | Nil)
  end
end

class UnregisteredHolder
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property value : Unregistered

  def initialize(@value : Unregistered)
  end
end

describe "types registered by the program" do
  it "round-trips a required field" do
    holder = CustomHolder.new(NodeId.new(0x1234_5678_9ABC_DEF0_u64))
    CustomHolder.from_slice(holder.to_slice).node.should eq(NodeId.new(0x1234_5678_9ABC_DEF0_u64))
  end

  it "round-trips a nilable field holding a value" do
    holder = OptionalCustomHolder.new(NodeId.new(42_u64), "present")
    decoded = OptionalCustomHolder.from_slice(holder.to_slice)
    decoded.node.should eq(NodeId.new(42_u64))
    decoded.label.should eq("present")
  end

  it "round-trips a nilable field holding nil" do
    holder = OptionalCustomHolder.new(nil, "absent")
    decoded = OptionalCustomHolder.from_slice(holder.to_slice)
    decoded.node.should be_nil
    decoded.label.should eq("absent")
  end

  it "picks the right member of a union of a custom type and a built-in one" do
    MixedUnionHolder.from_slice(MixedUnionHolder.new(NodeId.new(7_u64)).to_slice)
      .value.should eq(NodeId.new(7_u64))
    MixedUnionHolder.from_slice(MixedUnionHolder.new("seven").to_slice)
      .value.should eq("seven")
    MixedUnionHolder.from_slice(MixedUnionHolder.new(nil).to_slice)
      .value.should be_nil
  end

  it "reports an element no member of the union accepts" do
    # A float matches neither NodeId (an unsigned integer) nor String.
    bytes = TLV::Any.new({1_u8.as(TLV::TagId) => TLV::Any.new(1.5_f64, 1_u8)} of TLV::TagId => TLV::Any, nil).to_slice
    expect_raises(TLV::DeserializationError, /MixedUnionHolder.value/) do
      MixedUnionHolder.from_slice(bytes)
    end
  end

  it "reports a type with no registered overloads" do
    expect_raises(TLV::SerializationError, /Unsupported type for TLV serialization/) do
      UnregisteredHolder.new(Unregistered.new(1)).to_slice
    end
  end
end
