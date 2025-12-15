struct Float32
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : Float32
    TLV.parse(data).as_f32
  end
end

struct Float64
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : Float64
    TLV.parse(data).as_f64
  end
end
