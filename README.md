# TLV

Matter TLV encoder/decoder

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     tlv:
       github: spider-gazelle/tlv
   ```

2. Run `shards install`

## Usage

```crystal
require "tlv"

class User
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property first_name : String

  @[TLV::Field(tag: 2)]
  property last_name : String
end

class Packet
  include TLV::Serializable

  @[TLV::Field(tag: 1)]
  property id : UInt8

  @[TLV::Field(tag: 2)]
  property port : UInt16

  @[TLV::Field(tag: 3)]
  property? duplex : Bool

  @[TLV::Field(tag: 4)]
  property message : String

  @[TLV::Field(tag: 5)]
  property encoded_message : Bytes

  # arrays
  @[TLV::Field(tag: 6)]
  property array : Array(TLV::Value)

  # lists
  @[TLV::Field(tag: 1)]
  property list : Tuple(UInt8, String, UInt16)

  # Tuple serialized as TLV Array (homogeneous format)
  @[TLV::Field(tag: 1, container: :array)]
  property items : Tuple(UInt8, UInt8, UInt8)

  # Array serialized as TLV List (heterogeneous format)
  @[TLV::Field(tag: 1, container: :list)]
  property items : Array(UInt8)

  # Nested structures
  @[TLV::Field(tag: 7)]
  property user : User

  @[TLV::Field(tag: 8)]
  property optional_field : String?

  # nilable required field
  @[TLV::Field(tag: 9, optional: false)]
  property not_optional_field : String?

  # Common Profile Tag
  @[TLV::Field(tag: {0x235A, 42})]
  property common : UInt32

  # Vendor Profile Tag
  @[TLV::Field(tag: {0xFFFF, 0x235A, 42})]
  property vendor : UInt32
end

io = IO::Memory.new # bytes from network etc
packet = io.read_bytes(Packet)
packet.to_slice

```

There is also a `TLV::Any` type which should really only be used externally for payloads with an anonymous type. (i.e. no wrapping structure)

```crystal
require "tlv"

io = IO::Memory.new(Bytes[0x05, 0xF1, 0xFF]) # Anonymous UInt16 value 65521
any = io.read_bytes(TLV::Any)
any.header.element_type # => TLV::ElementType::UnsignedInt16
any.as_u16 # => 65521_u16
```

## Contributing

1. Fork it (<https://github.com/spider-gazelle/tlv/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Stephen von Takach](https://github.com/stakach) - creator and maintainer
