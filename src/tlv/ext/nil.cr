struct Nil
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : Nil
    TLV.parse(data).as_nil
  end
end
