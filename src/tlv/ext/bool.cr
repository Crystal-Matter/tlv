struct Bool
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : Bool
    TLV.parse(data).as_bool
  end
end
