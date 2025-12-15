struct Tuple
  def to_tlv(container : TLV::Container = :list) : Bytes
    list = TLV::List.new
    {% for i in 0...T.size %}
      list << TLV::Serializable.serialize_value(self[{{ i }}], nil)
    {% end %}
    TLV::Any.new(list, nil, as_array: container.array?).to_slice
  end

  def self.from_tlv(data : Bytes) : self
    any = TLV.parse(data)
    list = any.as_list
    {% begin %}
      {
        {% for type, index in T %}
          TLV::Serializable.deserialize_value(list[{{ index }}], {{ type }}),
        {% end %}
      }
    {% end %}
  end
end
