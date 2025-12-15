require "./header"

module TLV
  struct Any
    getter header : Header
    getter value : Types | Arrays | List | Structure

    def initialize(@header : Header, @value : Types | Arrays | List | Structure)
    end

    # Parse a single TLV element from IO
    def self.from_io(io : IO, format : IO::ByteFormat = IO::ByteFormat::LittleEndian) : Any
      header = Header.from_io(io)
      value = read_value(io, header.element_type)
      new(header, value)
    end

    # Parse from bytes
    def self.from_slice(bytes : Bytes) : Any
      from_io(IO::Memory.new(bytes))
    end

    # Write TLV element to IO
    def to_io(io : IO, format : IO::ByteFormat = IO::ByteFormat::LittleEndian) : Nil
      header.to_io(io)
      write_value(io, value, header.element_type)
    end

    # Serialize to bytes
    def to_slice : Bytes
      io = IO::Memory.new
      to_io(io)
      io.to_slice
    end

    # Read value based on element type
    protected def self.read_value(io : IO, element_type : ElementType) : Types | Arrays | List | Structure
      case element_type
      in .signed_int8?
        io.read_bytes(Int8, IO::ByteFormat::LittleEndian)
      in .signed_int16?
        io.read_bytes(Int16, IO::ByteFormat::LittleEndian)
      in .signed_int32?
        io.read_bytes(Int32, IO::ByteFormat::LittleEndian)
      in .signed_int64?
        io.read_bytes(Int64, IO::ByteFormat::LittleEndian)
      in .unsigned_int8?
        io.read_bytes(UInt8, IO::ByteFormat::LittleEndian)
      in .unsigned_int16?
        io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
      in .unsigned_int32?
        io.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      in .unsigned_int64?
        io.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      in .boolean_false?
        false
      in .boolean_true?
        true
      in .float32?
        io.read_bytes(Float32, IO::ByteFormat::LittleEndian)
      in .float64?
        io.read_bytes(Float64, IO::ByteFormat::LittleEndian)
      in .utf8_string1?
        read_string(io, io.read_bytes(UInt8, IO::ByteFormat::LittleEndian).to_u32)
      in .utf8_string2?
        read_string(io, io.read_bytes(UInt16, IO::ByteFormat::LittleEndian).to_u32)
      in .utf8_string4?
        read_string(io, io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
      in .utf8_string8?
        read_string(io, io.read_bytes(UInt64, IO::ByteFormat::LittleEndian).to_u32)
      in .byte_string1?
        read_bytes(io, io.read_bytes(UInt8, IO::ByteFormat::LittleEndian).to_u32)
      in .byte_string2?
        read_bytes(io, io.read_bytes(UInt16, IO::ByteFormat::LittleEndian).to_u32)
      in .byte_string4?
        read_bytes(io, io.read_bytes(UInt32, IO::ByteFormat::LittleEndian))
      in .byte_string8?
        read_bytes(io, io.read_bytes(UInt64, IO::ByteFormat::LittleEndian).to_u32)
      in .null?
        nil
      in .structure?
        read_structure(io)
      in .array?
        read_list(io) # Arrays are Lists in terms of parsing
      in .list?
        read_list(io)
      in .end_of_container?
        raise "Unexpected EndOfContainer"
      end
    end

    protected def self.read_string(io : IO, length : UInt32) : String
      bytes = Bytes.new(length)
      io.read_fully(bytes)
      String.new(bytes)
    end

    protected def self.read_bytes(io : IO, length : UInt32) : Bytes
      bytes = Bytes.new(length)
      io.read_fully(bytes)
      bytes
    end

    protected def self.read_structure(io : IO) : Structure
      result = Structure.new
      loop do
        header = Header.from_io(io)
        break if header.end_of_container?

        tag = header.ids
        value = read_value(io, header.element_type)

        # Structure elements must have tags (not anonymous)
        if tag.is_a?(UInt8)
          result[tag] = Any.new(header, value)
        elsif tag.is_a?(Tuple(UInt16, UInt16))
          result[tag] = Any.new(header, value)
        elsif tag.is_a?(Tuple(UInt16, UInt16, UInt16))
          result[tag] = Any.new(header, value)
        else
          raise "Structure elements must have tags, got: #{tag.inspect}"
        end
      end
      result
    end

    protected def self.read_list(io : IO) : List
      result = List.new
      loop do
        header = Header.from_io(io)
        break if header.end_of_container?

        value = read_value(io, header.element_type)
        result << Any.new(header, value)
      end
      result
    end

    # Write value to IO based on element type
    protected def write_value(io : IO, val : Types | Arrays | List | Structure, element_type : ElementType) : Nil
      case element_type
      in .signed_int8?
        io.write_bytes(val.as(Int8), IO::ByteFormat::LittleEndian)
      in .signed_int16?
        io.write_bytes(val.as(Int16), IO::ByteFormat::LittleEndian)
      in .signed_int32?
        io.write_bytes(val.as(Int32), IO::ByteFormat::LittleEndian)
      in .signed_int64?
        io.write_bytes(val.as(Int64), IO::ByteFormat::LittleEndian)
      in .unsigned_int8?
        io.write_bytes(val.as(UInt8), IO::ByteFormat::LittleEndian)
      in .unsigned_int16?
        io.write_bytes(val.as(UInt16), IO::ByteFormat::LittleEndian)
      in .unsigned_int32?
        io.write_bytes(val.as(UInt32), IO::ByteFormat::LittleEndian)
      in .unsigned_int64?
        io.write_bytes(val.as(UInt64), IO::ByteFormat::LittleEndian)
      in .boolean_false?, .boolean_true?
        # Boolean value is encoded in element type, no value bytes
      in .float32?
        io.write_bytes(val.as(Float32), IO::ByteFormat::LittleEndian)
      in .float64?
        io.write_bytes(val.as(Float64), IO::ByteFormat::LittleEndian)
      in .utf8_string1?
        str = val.as(String)
        io.write_bytes(str.bytesize.to_u8, IO::ByteFormat::LittleEndian)
        io.write(str.to_slice)
      in .utf8_string2?
        str = val.as(String)
        io.write_bytes(str.bytesize.to_u16, IO::ByteFormat::LittleEndian)
        io.write(str.to_slice)
      in .utf8_string4?
        str = val.as(String)
        io.write_bytes(str.bytesize.to_u32, IO::ByteFormat::LittleEndian)
        io.write(str.to_slice)
      in .utf8_string8?
        str = val.as(String)
        io.write_bytes(str.bytesize.to_u64, IO::ByteFormat::LittleEndian)
        io.write(str.to_slice)
      in .byte_string1?
        bytes = val.as(Bytes)
        io.write_bytes(bytes.size.to_u8, IO::ByteFormat::LittleEndian)
        io.write(bytes)
      in .byte_string2?
        bytes = val.as(Bytes)
        io.write_bytes(bytes.size.to_u16, IO::ByteFormat::LittleEndian)
        io.write(bytes)
      in .byte_string4?
        bytes = val.as(Bytes)
        io.write_bytes(bytes.size.to_u32, IO::ByteFormat::LittleEndian)
        io.write(bytes)
      in .byte_string8?
        bytes = val.as(Bytes)
        io.write_bytes(bytes.size.to_u64, IO::ByteFormat::LittleEndian)
        io.write(bytes)
      in .null?
        # No value bytes for null
      in .structure?
        write_structure(io, val.as(Structure))
      in .array?, .list?
        write_list(io, val.as(List))
      in .end_of_container?
        # No value bytes for end of container
      end
    end

    protected def write_structure(io : IO, structure : Structure) : Nil
      structure.each do |_, any|
        any.to_io(io)
      end
      # Write end of container
      end_header = Header.new(ElementType::EndOfContainer, nil)
      end_header.to_io(io)
    end

    protected def write_list(io : IO, list : List) : Nil
      list.each do |any|
        any.to_io(io)
      end
      # Write end of container
      end_header = Header.new(ElementType::EndOfContainer, nil)
      end_header.to_io(io)
    end

    # Access structure elements by tag
    def [](tag : TagId) : Any
      value.as(Structure)[tag]
    end

    def []?(tag : TagId) : Any?
      value.as?(Structure).try(&.[tag]?)
    end

    # Access list/array elements by index
    def [](index : Int32) : Any
      value.as(List)[index]
    end

    def []?(index : Int32) : Any?
      value.as?(List).try(&.[index]?)
    end

    # Get the raw value cast to specific types (with widening support)
    def as_i8 : Int8
      value.as(Int8)
    end

    def as_i16 : Int16
      v = value
      case v
      when Int8  then v.to_i16
      when Int16 then v
      else
        raise TypeCastError.new("Can't cast #{v.class} to Int16")
      end
    end

    def as_i32 : Int32
      v = value
      case v
      when Int8  then v.to_i32
      when Int16 then v.to_i32
      when Int32 then v
      else
        raise TypeCastError.new("Can't cast #{v.class} to Int32")
      end
    end

    def as_i64 : Int64
      v = value
      case v
      when Int8  then v.to_i64
      when Int16 then v.to_i64
      when Int32 then v.to_i64
      when Int64 then v
      else
        raise TypeCastError.new("Can't cast #{v.class} to Int64")
      end
    end

    def as_u8 : UInt8
      value.as(UInt8)
    end

    def as_u16 : UInt16
      v = value
      case v
      when UInt8  then v.to_u16
      when UInt16 then v
      else
        raise TypeCastError.new("Can't cast #{v.class} to UInt16")
      end
    end

    def as_u32 : UInt32
      v = value
      case v
      when UInt8  then v.to_u32
      when UInt16 then v.to_u32
      when UInt32 then v
      else
        raise TypeCastError.new("Can't cast #{v.class} to UInt32")
      end
    end

    def as_u64 : UInt64
      v = value
      case v
      when UInt8  then v.to_u64
      when UInt16 then v.to_u64
      when UInt32 then v.to_u64
      when UInt64 then v
      else
        raise TypeCastError.new("Can't cast #{v.class} to UInt64")
      end
    end

    def as_bool : Bool
      value.as(Bool)
    end

    def as_f32 : Float32
      value.as(Float32)
    end

    def as_f64 : Float64
      value.as(Float64)
    end

    def as_s : String
      value.as(String)
    end

    def as_bytes : Bytes
      value.as(Bytes)
    end

    def as_nil : Nil
      value.as(Nil)
    end

    def as_list : List
      value.as(List)
    end

    def as_structure : Structure
      value.as(Structure)
    end

    # Check if this is a container
    def container? : Bool
      header.container?
    end

    # Iterate over structure entries (tag, value pairs)
    def each_pair(& : TagId, Any ->)
      value.as(Structure).each do |k, v|
        yield k, v
      end
    end

    # Iterate over list/array entries
    def each(& : Any ->)
      value.as(List).each do |v|
        yield v
      end
    end

    # Get size of container
    def size : Int32
      case v = value
      when Structure then v.size
      when List      then v.size
      else                raise "Not a container"
      end
    end

    # Create TLV::Any from Crystal values
    def self.new(value : Nil, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      header = Header.new(ElementType::Null, tag)
      new(header, value)
    end

    def self.new(value : Bool, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      element_type = value ? ElementType::BooleanTrue : ElementType::BooleanFalse
      header = Header.new(element_type, tag)
      new(header, value)
    end

    # Signed integers - use minimum-size encoding
    def self.new(value : Int8, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      header = Header.new(ElementType::SignedInt8, tag)
      new(header, value)
    end

    def self.new(value : Int16, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, fixed_size : Bool = false) : Any
      if fixed_size
        header = Header.new(ElementType::SignedInt16, tag)
        new(header, value)
      elsif value >= Int8::MIN && value <= Int8::MAX
        # Use minimum-size encoding
        header = Header.new(ElementType::SignedInt8, tag)
        new(header, value.to_i8)
      else
        header = Header.new(ElementType::SignedInt16, tag)
        new(header, value)
      end
    end

    def self.new(value : Int32, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, fixed_size : Bool = false) : Any
      if fixed_size
        header = Header.new(ElementType::SignedInt32, tag)
        new(header, value)
      elsif value >= Int8::MIN && value <= Int8::MAX
        # Use minimum-size encoding
        header = Header.new(ElementType::SignedInt8, tag)
        new(header, value.to_i8)
      elsif value >= Int16::MIN && value <= Int16::MAX
        header = Header.new(ElementType::SignedInt16, tag)
        new(header, value.to_i16)
      else
        header = Header.new(ElementType::SignedInt32, tag)
        new(header, value)
      end
    end

    def self.new(value : Int64, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, fixed_size : Bool = false) : Any
      if fixed_size
        header = Header.new(ElementType::SignedInt64, tag)
        new(header, value)
      elsif value >= Int8::MIN && value <= Int8::MAX
        # Use minimum-size encoding
        header = Header.new(ElementType::SignedInt8, tag)
        new(header, value.to_i8)
      elsif value >= Int16::MIN && value <= Int16::MAX
        header = Header.new(ElementType::SignedInt16, tag)
        new(header, value.to_i16)
      elsif value >= Int32::MIN && value <= Int32::MAX
        header = Header.new(ElementType::SignedInt32, tag)
        new(header, value.to_i32)
      else
        header = Header.new(ElementType::SignedInt64, tag)
        new(header, value)
      end
    end

    # Unsigned integers - use minimum-size encoding
    def self.new(value : UInt8, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      header = Header.new(ElementType::UnsignedInt8, tag)
      new(header, value)
    end

    def self.new(value : UInt16, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, fixed_size : Bool = false) : Any
      if fixed_size
        header = Header.new(ElementType::UnsignedInt16, tag)
        new(header, value)
      elsif value <= UInt8::MAX
        # Use minimum-size encoding
        header = Header.new(ElementType::UnsignedInt8, tag)
        new(header, value.to_u8)
      else
        header = Header.new(ElementType::UnsignedInt16, tag)
        new(header, value)
      end
    end

    def self.new(value : UInt32, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, fixed_size : Bool = false) : Any
      if fixed_size
        header = Header.new(ElementType::UnsignedInt32, tag)
        new(header, value)
      elsif value <= UInt8::MAX
        # Use minimum-size encoding
        header = Header.new(ElementType::UnsignedInt8, tag)
        new(header, value.to_u8)
      elsif value <= UInt16::MAX
        header = Header.new(ElementType::UnsignedInt16, tag)
        new(header, value.to_u16)
      else
        header = Header.new(ElementType::UnsignedInt32, tag)
        new(header, value)
      end
    end

    def self.new(value : UInt64, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, fixed_size : Bool = false) : Any
      if fixed_size
        header = Header.new(ElementType::UnsignedInt64, tag)
        new(header, value)
      elsif value <= UInt8::MAX
        # Use minimum-size encoding
        header = Header.new(ElementType::UnsignedInt8, tag)
        new(header, value.to_u8)
      elsif value <= UInt16::MAX
        header = Header.new(ElementType::UnsignedInt16, tag)
        new(header, value.to_u16)
      elsif value <= UInt32::MAX
        header = Header.new(ElementType::UnsignedInt32, tag)
        new(header, value.to_u32)
      else
        header = Header.new(ElementType::UnsignedInt64, tag)
        new(header, value)
      end
    end

    def self.new(value : Float32, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      header = Header.new(ElementType::Float32, tag)
      new(header, value)
    end

    def self.new(value : Float64, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      header = Header.new(ElementType::Float64, tag)
      new(header, value)
    end

    def self.new(value : String, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      element_type = string_element_type(value.bytesize)
      header = Header.new(element_type, tag)
      new(header, value)
    end

    def self.new(value : Bytes, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      element_type = bytes_element_type(value.size)
      header = Header.new(element_type, tag)
      new(header, value)
    end

    def self.new(value : Structure, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : Any
      header = Header.new(ElementType::Structure, tag)
      new(header, value)
    end

    def self.new(value : List, tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil, *, as_array : Bool = false) : Any
      element_type = as_array ? ElementType::Array : ElementType::List
      header = Header.new(element_type, tag)
      new(header, value)
    end

    protected def self.string_element_type(bytesize : Int32) : ElementType
      if bytesize <= UInt8::MAX
        ElementType::UTF8String1
      elsif bytesize <= UInt16::MAX
        ElementType::UTF8String2
      elsif bytesize <= UInt32::MAX
        ElementType::UTF8String4
      else
        ElementType::UTF8String8
      end
    end

    protected def self.bytes_element_type(size : Int32) : ElementType
      if size <= UInt8::MAX
        ElementType::ByteString1
      elsif size <= UInt16::MAX
        ElementType::ByteString2
      elsif size <= UInt32::MAX
        ElementType::ByteString4
      else
        ElementType::ByteString8
      end
    end
  end
end
