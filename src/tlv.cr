require "./tlv/**"

module TLV
  alias Types = Nil | UInt8 | UInt16 | UInt32 | UInt64 | Int8 | Int16 | Int32 | Int64 | Bool | Float32 | Float64 | String | Bytes
  alias Arrays = Array(UInt8) | Array(UInt16) | Array(UInt32) | Array(UInt64) | Array(Int8) | Array(Int16) | Array(Int32) | Array(Int64) | Array(Bool) | Array(Float32) | Array(Float64) | Array(String) | Array(Bytes)
  alias List = Array(TLV::Any)
  # TagId supports context tags (UInt8), common profile tags, and vendor profile tags
  alias TagId = UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16}
  alias Structure = Hash(TagId, TLV::Any)

  def self.parse(io : IO) : TLV::Any
    TLV::Any.from_io(io)
  end

  def self.parse(bytes : Bytes) : TLV::Any
    parse IO::Memory.new(bytes)
  end
end
