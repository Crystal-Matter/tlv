class String
  def to_tlv : Bytes
    TLV::Any.new(self, nil).to_slice
  end

  def self.from_tlv(data : Bytes) : String
    TLV.parse(data).as_s
  end
end
