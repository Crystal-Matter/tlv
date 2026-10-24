require "./spec_helper"

private struct FieldStateEnvelope
  include TLV::Serializable

  @[TLV::Field(tag: 0)]
  getter id : UInt8

  @[TLV::Field(tag: 1)]
  getter stream_id : TLV::FieldState(UInt16)

  @[TLV::Field(tag: 2)]
  getter zones : TLV::FieldState(Array(UInt16))

  def initialize(@id : UInt8, @stream_id : TLV::FieldState(UInt16),
                 @zones : TLV::FieldState(Array(UInt16)))
  end
end

private struct FieldStateChild
  include TLV::Serializable

  @[TLV::Field(tag: 0)]
  getter id : UInt16

  def initialize(@id : UInt16); end
end

private struct FieldStateContainers
  include TLV::Serializable

  @[TLV::Field(tag: 0, container: :list)]
  getter ids : TLV::FieldState(Array(UInt8))

  @[TLV::Field(tag: 1)]
  getter child : TLV::FieldState(FieldStateChild)

  def initialize(@ids : TLV::FieldState(Array(UInt8)), @child : TLV::FieldState(FieldStateChild)); end
end

describe TLV::FieldState do
  it "round trips an absent optional field without adding a TLV tag" do
    value = FieldStateEnvelope.new(1_u8, TLV::FieldState(UInt16).absent,
      TLV::FieldState(Array(UInt16)).absent)
    wire = value.to_tlv(nil)
    wire.as_structure.keys.should eq([0_u8])
    parsed = FieldStateEnvelope.from_slice(value.to_slice)
    parsed.stream_id.absent?.should be_true
    parsed.zones.absent?.should be_true
  end

  it "round trips explicit Null separately from absent for scalar and list fields" do
    value = FieldStateEnvelope.new(1_u8, TLV::FieldState(UInt16).null,
      TLV::FieldState(Array(UInt16)).null)
    wire = value.to_tlv(nil)
    wire.as_structure.keys.should eq([0_u8, 1_u8, 2_u8])
    wire.as_structure[1_u8].header.element_type.null?.should be_true
    wire.as_structure[2_u8].header.element_type.null?.should be_true
    parsed = FieldStateEnvelope.from_slice(value.to_slice)
    parsed.stream_id.null?.should be_true
    parsed.zones.null?.should be_true
  end

  it "round trips typed values and rejects malformed non-null types" do
    value = FieldStateEnvelope.new(1_u8, TLV::FieldState(UInt16).value(42_u16),
      TLV::FieldState(Array(UInt16)).value([1_u16, 2_u16]))
    parsed = FieldStateEnvelope.from_slice(value.to_slice)
    parsed.stream_id.value!.should eq(42_u16)
    parsed.zones.value!.should eq([1_u16, 2_u16])

    malformed = TLV::Structure.new
    malformed[0_u8] = TLV::Any.new(1_u8, 0_u8)
    malformed[1_u8] = TLV::Any.new("not an ID", 1_u8)
    expect_raises(TLV::DeserializationError) do
      FieldStateEnvelope.from_tlv(TLV::Any.new(malformed))
    end

    malformed[1_u8] = TLV::Any.new(42_u16, 1_u8)
    malformed[2_u8] = TLV::Any.new("not a zone list", 2_u8)
    expect_raises(TLV::DeserializationError) do
      FieldStateEnvelope.from_tlv(TLV::Any.new(malformed))
    end
  end

  it "works with explicit TLV List containers and nested structures" do
    value = FieldStateContainers.new(TLV::FieldState(Array(UInt8)).value([1_u8, 2_u8]),
      TLV::FieldState(FieldStateChild).value(FieldStateChild.new(7_u16)))
    wire = value.to_tlv(nil).as_structure
    wire[0_u8].header.element_type.list?.should be_true
    wire[1_u8].header.element_type.structure?.should be_true
    parsed = FieldStateContainers.from_slice(value.to_slice)
    parsed.ids.value!.should eq([1_u8, 2_u8])
    parsed.child.value!.id.should eq(7_u16)
  end
end
