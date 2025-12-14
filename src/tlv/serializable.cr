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
            %structure = any.value.as?(TLV::Structure)
            if %structure.nil?
              %actual_type = any.value.class.name
              raise ::TLV::DeserializationError.new(
                "Cannot deserialize {{ @type }}: expected TLV Structure, got #{%actual_type} (element_type: #{any.header.element_type})"
              )
            end

            {% for ivar in @type.instance_vars %}
              {% ann = ivar.annotation(::TLV::Field) %}
              {% if ann %}
                {% tag = ann[:tag] %}
                {% type = ivar.type %}
                {% optional = ann[:optional] != false && ivar.type.nilable? %}
                {% has_default = ivar.has_default_value? %}
                {% is_tuple = type.name.starts_with?("Tuple(") || (type.union? && type.union_types.any?(&.name.starts_with?("Tuple("))) %}

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
                    {% if is_tuple %}
                      @{{ ivar.name }} = ::TLV::Serializable.deserialize_tuple_field(
                        %found{ivar.name}.not_nil!,
                        {{ type.id }},
                        {{ @type.stringify }},
                        {{ ivar.name.stringify }},
                        {{ lookup_key.stringify }}
                      )
                    {% else %}
                      @{{ ivar.name }} = ::TLV::Serializable.deserialize_field(
                        %found{ivar.name}.not_nil!,
                        {{ type.id }},
                        {{ @type.stringify }},
                        {{ ivar.name.stringify }},
                        {{ lookup_key.stringify }}
                      )
                    {% end %}
                  else
                    @{{ ivar.name }} = nil
                  end
                {% elsif has_default %}
                  if %found{ivar.name}
                    {% if is_tuple %}
                      @{{ ivar.name }} = ::TLV::Serializable.deserialize_tuple_field(
                        %found{ivar.name}.not_nil!,
                        {{ type.id }},
                        {{ @type.stringify }},
                        {{ ivar.name.stringify }},
                        {{ lookup_key.stringify }}
                      )
                    {% else %}
                      @{{ ivar.name }} = ::TLV::Serializable.deserialize_field(
                        %found{ivar.name}.not_nil!,
                        {{ type.id }},
                        {{ @type.stringify }},
                        {{ ivar.name.stringify }},
                        {{ lookup_key.stringify }}
                      )
                    {% end %}
                  else
                    @{{ ivar.name }} = {{ ivar.default_value }}
                  end
                {% else %}
                  %any{ivar.name} = %found{ivar.name}
                  if %any{ivar.name}.nil?
                    raise ::TLV::DeserializationError.new(
                      "{{ @type }}: missing required field '{{ ivar.name }}' (tag {{ lookup_key }})"
                    )
                  end
                  {% if is_tuple %}
                    @{{ ivar.name }} = ::TLV::Serializable.deserialize_tuple_field(
                      %any{ivar.name}.not_nil!,
                      {{ type.id }},
                      {{ @type.stringify }},
                      {{ ivar.name.stringify }},
                      {{ lookup_key.stringify }}
                    )
                  {% else %}
                    @{{ ivar.name }} = ::TLV::Serializable.deserialize_field(
                      %any{ivar.name}.not_nil!,
                      {{ type.id }},
                      {{ @type.stringify }},
                      {{ ivar.name.stringify }},
                      {{ lookup_key.stringify }}
                    )
                  {% end %}
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
                {% type = ivar.type %}
                {% optional = ann[:optional] != false && ivar.type.nilable? %}
                {% container = ann[:container] %}
                {% is_tuple = type.name.starts_with?("Tuple(") || (type.union? && type.union_types.any?(&.name.starts_with?("Tuple("))) %}
                {% is_array = type.name.starts_with?("Array(") || (type.union? && type.union_types.any?(&.name.starts_with?("Array("))) %}

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
                    {% if is_tuple %}
                      # Tuple: default to list, use array if container: :array
                      %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_tuple(%value{ivar.name}, {{ type.id }}, {{ tag_value }}, {{ container == :array }})
                    {% elsif is_array && container == :list %}
                      # Array with container: :list - force list format
                      %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_array_as_list(%value{ivar.name}, {{ tag_value }})
                    {% else %}
                      %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_value(%value{ivar.name}, {{ tag_value }})
                    {% end %}
                  end
                {% else %}
                  {% if is_tuple %}
                    # Tuple: default to list, use array if container: :array
                    %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_tuple(%value{ivar.name}, {{ type.id }}, {{ tag_value }}, {{ container == :array }})
                  {% elsif is_array && container == :list %}
                    # Array with container: :list - force list format
                    %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_array_as_list(%value{ivar.name}, {{ tag_value }})
                  {% else %}
                    %structure[{{ tag_value }}] = ::TLV::Serializable.serialize_value(%value{ivar.name}, {{ tag_value }})
                  {% end %}
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
      # Support widening from smaller integer types
      v = any.value
      case v
      when Int8  then v.to_i16
      when Int16 then v
      else            any.as_i16
      end
    end

    def self.deserialize_value(any : TLV::Any, type : Int32.class) : Int32
      # Support widening from smaller integer types
      v = any.value
      case v
      when Int8  then v.to_i32
      when Int16 then v.to_i32
      when Int32 then v
      else            any.as_i32
      end
    end

    def self.deserialize_value(any : TLV::Any, type : Int64.class) : Int64
      # Support widening from smaller integer types
      v = any.value
      case v
      when Int8  then v.to_i64
      when Int16 then v.to_i64
      when Int32 then v.to_i64
      when Int64 then v
      else            any.as_i64
      end
    end

    def self.deserialize_value(any : TLV::Any, type : UInt8.class) : UInt8
      any.as_u8
    end

    def self.deserialize_value(any : TLV::Any, type : UInt16.class) : UInt16
      # Support widening from smaller integer types
      v = any.value
      case v
      when UInt8  then v.to_u16
      when UInt16 then v
      else             any.as_u16
      end
    end

    def self.deserialize_value(any : TLV::Any, type : UInt32.class) : UInt32
      # Support widening from smaller integer types
      v = any.value
      case v
      when UInt8  then v.to_u32
      when UInt16 then v.to_u32
      when UInt32 then v
      else             any.as_u32
      end
    end

    def self.deserialize_value(any : TLV::Any, type : UInt64.class) : UInt64
      # Support widening from smaller integer types
      v = any.value
      case v
      when UInt8  then v.to_u64
      when UInt16 then v.to_u64
      when UInt32 then v.to_u64
      when UInt64 then v
      else             any.as_u64
      end
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

    # Handle Serializable types and union types (catch-all with macro check)
    def self.deserialize_value(any : TLV::Any, type : T.class) : T forall T
      {% if T.union? %}
        {% union_types = T.union_types %}
        {% has_nil = union_types.any?(&.==(Nil)) %}
        {% non_nil_types = union_types.reject(&.==(Nil)) %}

        # Handle null element type for nilable unions
        {% if has_nil %}
          if any.header.element_type.null?
            return nil
          end
        {% end %}

        # Try to match the TLV element type to one of the union types
        # Note: TLV uses minimum-size encoding, so we need to handle integer widening
        element_type = any.header.element_type
        {% for ut in non_nil_types %}
          {% if ut == Bool %}
            if element_type.boolean_true? || element_type.boolean_false?
              return any.as_bool
            end
          {% elsif ut == String %}
            if element_type.utf8_string1? || element_type.utf8_string2? || element_type.utf8_string4? || element_type.utf8_string8?
              return any.as_s
            end
          {% elsif ut == Bytes %}
            if element_type.byte_string1? || element_type.byte_string2? || element_type.byte_string4? || element_type.byte_string8?
              return any.as_bytes
            end
          {% elsif ut == Int8 %}
            if element_type.signed_int8?
              return any.as_i8
            end
          {% elsif ut == Int16 %}
            # Accept Int8 or Int16 for Int16 target (widening)
            if element_type.signed_int8? || element_type.signed_int16?
              return any.as_i16
            end
          {% elsif ut == Int32 %}
            # Accept Int8, Int16, or Int32 for Int32 target (widening)
            if element_type.signed_int8? || element_type.signed_int16? || element_type.signed_int32?
              return any.as_i32
            end
          {% elsif ut == Int64 %}
            # Accept any signed int for Int64 target (widening)
            if element_type.signed_int8? || element_type.signed_int16? || element_type.signed_int32? || element_type.signed_int64?
              return any.as_i64
            end
          {% elsif ut == UInt8 %}
            if element_type.unsigned_int8?
              return any.as_u8
            end
          {% elsif ut == UInt16 %}
            # Accept UInt8 or UInt16 for UInt16 target (widening)
            if element_type.unsigned_int8? || element_type.unsigned_int16?
              return any.as_u16
            end
          {% elsif ut == UInt32 %}
            # Accept UInt8, UInt16, or UInt32 for UInt32 target (widening)
            if element_type.unsigned_int8? || element_type.unsigned_int16? || element_type.unsigned_int32?
              return any.as_u32
            end
          {% elsif ut == UInt64 %}
            # Accept any unsigned int for UInt64 target (widening)
            if element_type.unsigned_int8? || element_type.unsigned_int16? || element_type.unsigned_int32? || element_type.unsigned_int64?
              return any.as_u64
            end
          {% elsif ut == Float32 %}
            if element_type.float32?
              return any.as_f32
            end
          {% elsif ut == Float64 %}
            if element_type.float64?
              return any.as_f64
            end
          {% elsif ut < ::TLV::Serializable %}
            if element_type.structure?
              return {{ ut }}.from_tlv(any)
            end
          {% end %}
        {% end %}

        # If no type matched, raise an error
        raise "Cannot deserialize TLV element type #{element_type} to union type #{T}"
      {% elsif T < ::TLV::Serializable %}
        T.from_tlv(any)
      {% else %}
        raise "Unsupported type for TLV deserialization: #{T}"
      {% end %}
    end

    # Handle Arrays - elements are stored as TLV List/Array
    def self.deserialize_value(any : TLV::Any, type : Array(T).class) : Array(T) forall T
      list = any.as_list
      list.map { |elem| deserialize_value(elem, T) }
    end

    # Handle Tuples - elements are stored as TLV List
    macro deserialize_tuple(any, tuple_type)
      %list = {{ any }}.as_list
      {% types = tuple_type.type_vars %}
      {
        {% for type, index in types %}
          ::TLV::Serializable.deserialize_value(%list[{{ index }}], {{ type }}),
        {% end %}
      }
    end

    # Handle Tuples with error context
    macro deserialize_tuple_field(any, tuple_type, class_name, field_name, tag)
      begin
        %list = {{ any }}.as_list
        {% types = tuple_type.type_vars %}
        {
          {% for type, index in types %}
            ::TLV::Serializable.deserialize_value(%list[{{ index }}], {{ type }}),
          {% end %}
        }
      rescue ex : TypeCastError
        %actual_type = {{ any }}.value.class.name
        raise ::TLV::DeserializationError.new(
          "#{{{ class_name }}}.#{{{ field_name }}}: expected #{{{ tuple_type.stringify }}}, got #{%actual_type} (element_type: #{{{ any }}.header.element_type}, tag: #{{{ tag }}})"
        )
      end
    end

    # Wrapper for deserialization with improved error messages
    def self.deserialize_field(any : TLV::Any, type : T.class, class_name : String, field_name : String, tag : String) : T forall T
      deserialize_value(any, T)
    rescue ex : TypeCastError
      actual_type = any.value.class.name
      raise ::TLV::DeserializationError.new(
        "#{class_name}.#{field_name}: expected #{T}, got #{actual_type} (element_type: #{any.header.element_type}, tag: #{tag})"
      )
    rescue ex : ::TLV::DeserializationError
      # Add context to nested deserialization errors
      raise ::TLV::DeserializationError.new(
        "#{class_name}.#{field_name} (tag: #{tag}): #{ex.message}"
      )
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

    # Handle Arrays - default to TLV Array
    def self.serialize_value(value : Array(T), tag) : TLV::Any forall T
      list = TLV::List.new
      value.each do |elem|
        list << serialize_value(elem, nil) # Elements are anonymous
      end
      TLV::Any.new(list, tag, as_array: true)
    end

    # Handle Arrays - serialize as TLV List (heterogeneous format)
    def self.serialize_array_as_list(value : Array(T), tag) : TLV::Any forall T
      list = TLV::List.new
      value.each do |elem|
        list << serialize_value(elem, nil) # Elements are anonymous
      end
      TLV::Any.new(list, tag, as_array: false)
    end

    # Handle Tuples - serialize each element, default to TLV List
    macro serialize_tuple(value, tuple_type, tag, as_array = false)
      %list = TLV::List.new
      {% types = tuple_type.type_vars %}
      {% for i in 0...types.size %}
        %list << ::TLV::Serializable.serialize_value({{ value }}[{{ i }}], nil)
      {% end %}
      TLV::Any.new(%list, {{ tag }}, as_array: {{ as_array }})
    end
  end
end
