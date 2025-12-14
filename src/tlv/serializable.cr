require "./header"
require "./any"

module TLV
  annotation Field
  end

  module Serializable
    macro included
      def self.from_io(io : IO, format : IO::ByteFormat = IO::ByteFormat::LittleEndian)
        any = TLV::Any.from_io(io)
        from_tlv(any)
      end

      def self.from_slice(bytes : Bytes)
        from_io(IO::Memory.new(bytes))
      end

      def self.from_tlv(any : TLV::Any)
        new(any)
      end

      def to_io(io : IO, format : IO::ByteFormat = IO::ByteFormat::LittleEndian) : Nil
        to_tlv.to_io(io, format)
      end

      def to_slice : Bytes
        io = IO::Memory.new
        to_io(io)
        io.to_slice
      end

      def initialize(any : TLV::Any)
        {% verbatim do %}
          {% begin %}
            %structure = any.value.as(TLV::Structure)

            {% for ivar in @type.instance_vars %}
              {% ann = ivar.annotation(::TLV::Field) %}
              {% if ann %}
                {% tag = ann[:tag] %}
                {% type = ivar.type %}
                {% optional = ann[:optional] != false && ivar.type.nilable? %}
                {% has_default = ivar.has_default_value? %}

                {% # Determine the lookup key for the structure hash
                   lookup_key = if tag.is_a?(NumberLiteral)
                                  "#{tag}_u8".id
                                elsif tag.is_a?(TupleLiteral) && tag.size == 2
                                  "{#{tag[0]}_u16, #{tag[1]}_u16}".id
                                elsif tag.is_a?(TupleLiteral) && tag.size == 3
                                  "{#{tag[0]}_u16, #{tag[1]}_u16, #{tag[2]}_u16}".id
                                else
                                  raise "Invalid tag format: #{tag}"
                                end %}

                %found{ivar.name} = %structure[{{ lookup_key }}]?

                {% if optional %}
                  if %found{ivar.name}
                    @{{ ivar.name }} = ::TLV::Serializable.deserialize_value(%found{ivar.name}.not_nil!, {{ type.id }})
                  else
                    @{{ ivar.name }} = nil
                  end
                {% elsif has_default %}
                  if %found{ivar.name}
                    @{{ ivar.name }} = ::TLV::Serializable.deserialize_value(%found{ivar.name}.not_nil!, {{ type.id }})
                  else
                    @{{ ivar.name }} = {{ ivar.default_value }}
                  end
                {% else %}
                  %any{ivar.name} = %found{ivar.name}
                  if %any{ivar.name}.nil?
                    raise "Missing required TLV field: {{ ivar.name }} (tag {{ lookup_key }})"
                  end
                  @{{ ivar.name }} = ::TLV::Serializable.deserialize_value(%any{ivar.name}.not_nil!, {{ type.id }})
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      end

      def to_tlv(outer_tag : Nil | UInt8 | {UInt16, UInt16} | {UInt16, UInt16, UInt16} = nil) : TLV::Any
        {% verbatim do %}
          {% begin %}
            %structure = TLV::Structure.new

            {% for ivar in @type.instance_vars %}
              {% ann = ivar.annotation(::TLV::Field) %}
              {% if ann %}
                {% tag = ann[:tag] %}
                {% optional = ann[:optional] != false && ivar.type.nilable? %}

                {% # Determine the tag format (used for both hash key and TLV::Any tag)
                   if tag.is_a?(NumberLiteral)
                     tag_value = "#{tag}_u8".id
                   elsif tag.is_a?(TupleLiteral) && tag.size == 2
                     tag_value = "{#{tag[0]}_u16, #{tag[1]}_u16}".id
                   elsif tag.is_a?(TupleLiteral) && tag.size == 3
                     tag_value = "{#{tag[0]}_u16, #{tag[1]}_u16, #{tag[2]}_u16}".id
                   end %}

                %value{ivar.name} = @{{ ivar.name }}

                {% if optional %}
                  unless %value{ivar.name}.nil?
                    %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_value(%value{ivar.name}, {{ tag_value }})
                  end
                {% else %}
                  %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_value(%value{ivar.name}, {{ tag_value }})
                {% end %}
              {% end %}
            {% end %}

            TLV::Any.new(%structure, outer_tag)
          {% end %}
        {% end %}
      end
    end

    # Helper methods for deserialization
    def self.deserialize_value(any : TLV::Any, type : Nil.class) : Nil
      any.as_nil
    end

    def self.deserialize_value(any : TLV::Any, type : Bool.class) : Bool
      any.as_bool
    end

    def self.deserialize_value(any : TLV::Any, type : Int8.class) : Int8
      any.as_i8
    end

    def self.deserialize_value(any : TLV::Any, type : Int16.class) : Int16
      any.as_i16
    end

    def self.deserialize_value(any : TLV::Any, type : Int32.class) : Int32
      any.as_i32
    end

    def self.deserialize_value(any : TLV::Any, type : Int64.class) : Int64
      any.as_i64
    end

    def self.deserialize_value(any : TLV::Any, type : UInt8.class) : UInt8
      any.as_u8
    end

    def self.deserialize_value(any : TLV::Any, type : UInt16.class) : UInt16
      any.as_u16
    end

    def self.deserialize_value(any : TLV::Any, type : UInt32.class) : UInt32
      any.as_u32
    end

    def self.deserialize_value(any : TLV::Any, type : UInt64.class) : UInt64
      any.as_u64
    end

    def self.deserialize_value(any : TLV::Any, type : Float32.class) : Float32
      any.as_f32
    end

    def self.deserialize_value(any : TLV::Any, type : Float64.class) : Float64
      any.as_f64
    end

    def self.deserialize_value(any : TLV::Any, type : String.class) : String
      any.as_s
    end

    def self.deserialize_value(any : TLV::Any, type : Bytes.class) : Bytes
      any.as_bytes
    end

    def self.deserialize_value(any : TLV::Any, type : TLV::Any.class) : TLV::Any
      any
    end

    # Handle Serializable types (catch-all with macro check)
    def self.deserialize_value(any : TLV::Any, type : T.class) : T forall T
      {% if T.nilable? %}
        {% non_nil_type = T.union_types.reject(&.==(Nil)).first %}
        if any.header.element_type.null?
          nil
        else
          deserialize_value(any, {{ non_nil_type }})
        end
      {% elsif T < ::TLV::Serializable %}
        T.from_tlv(any)
      {% else %}
        raise "Unsupported type for TLV deserialization: #{T}"
      {% end %}
    end

    # Handle Arrays - elements are stored as TLV List
    def self.deserialize_value(any : TLV::Any, type : Array(T).class) : Array(T) forall T
      list = any.as_list
      list.map { |elem| deserialize_value(elem, T) }
    end

    # Helper methods for serialization
    def self.serialize_value(value : Nil, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Bool, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Int8, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Int16, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Int32, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Int64, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : UInt8, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : UInt16, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : UInt32, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : UInt64, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Float32, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Float64, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : String, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : Bytes, tag) : TLV::Any
      TLV::Any.new(value, tag)
    end

    def self.serialize_value(value : TLV::Any, tag) : TLV::Any
      # Re-tag the Any with the new tag
      header = TLV::Header.new(value.header.element_type, tag)
      TLV::Any.new(header, value.value)
    end

    # Handle Serializable types (catch-all)
    def self.serialize_value(value : T, tag) : TLV::Any forall T
      {% if T < ::TLV::Serializable %}
        value.to_tlv(tag)
      {% else %}
        raise "Unsupported type for TLV serialization: #{T}"
      {% end %}
    end

    # Handle Arrays
    def self.serialize_value(value : Array(T), tag) : TLV::Any forall T
      list = TLV::List.new
      value.each do |elem|
        list << serialize_value(elem, nil) # Array elements are anonymous
      end
      TLV::Any.new(list, tag, as_array: true)
    end
  end
end
