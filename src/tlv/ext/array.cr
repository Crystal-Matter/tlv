class Array(T)
  def to_tlv(container : TLV::Container = :array) : Bytes
    list = TLV::List.new
    each do |elem|
      list << TLV::Serializable.serialize_value(elem, nil)
    end
    TLV::Any.new(list, nil, as_array: container.array?).to_slice
  end

  def self.from_tlv(data : Bytes) : Array(T)
    any = TLV.parse(data)
    any.as_list.map { |elem| TLV::Serializable.deserialize_value(elem, T) }
  end
end
