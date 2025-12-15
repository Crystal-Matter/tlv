struct Slice(T)
  def to_tlv : Bytes
    {% if T == UInt8 %}
      TLV::Any.new(self, nil).to_slice
    {% else %}
      {% raise "TLV serialization only supports Slice(UInt8) (Bytes)" %}
    {% end %}
  end

  def self.from_tlv(data : Bytes) : self
    {% if T == UInt8 %}
      TLV.parse(data).as_bytes
    {% else %}
      {% raise "TLV deserialization only supports Slice(UInt8) (Bytes)" %}
    {% end %}
  end
end
