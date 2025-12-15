struct Int8
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : Int8
    TLV.parse(data).as_i8
  end
end

struct Int16
  def to_tlv(*, fixed_size : Bool = false) : Bytes
    TLV::Any.new(self, nil, fixed_size: fixed_size).to_slice
  end

  def self.from_tlv(data : Bytes) : Int16
    TLV.parse(data).as_i16
  end
end

struct Int32
  def to_tlv(*, fixed_size : Bool = false) : Bytes
    TLV::Any.new(self, nil, fixed_size: fixed_size).to_slice
  end

  def self.from_tlv(data : Bytes) : Int32
    TLV.parse(data).as_i32
  end
end

struct Int64
  def to_tlv(*, fixed_size : Bool = false) : Bytes
    TLV::Any.new(self, nil, fixed_size: fixed_size).to_slice
  end

  def self.from_tlv(data : Bytes) : Int64
    TLV.parse(data).as_i64
  end
end

struct UInt8
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : UInt8
    TLV.parse(data).as_u8
  end
end

struct UInt16
  def to_tlv(*, fixed_size : Bool = false) : Bytes
    TLV::Any.new(self, nil, fixed_size: fixed_size).to_slice
  end

  def self.from_tlv(data : Bytes) : UInt16
    TLV.parse(data).as_u16
  end
end

struct UInt32
  def to_tlv(*, fixed_size : Bool = false) : Bytes
    TLV::Any.new(self, nil, fixed_size: fixed_size).to_slice
  end

  def self.from_tlv(data : Bytes) : UInt32
    TLV.parse(data).as_u32
  end
end

struct UInt64
  def to_tlv(*, fixed_size : Bool = false) : Bytes
    TLV::Any.new(self, nil, fixed_size: fixed_size).to_slice
  end

  def self.from_tlv(data : Bytes) : UInt64
    TLV.parse(data).as_u64
  end
end
