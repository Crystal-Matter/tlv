module TLV
  # A field that may be omitted, explicitly Null, or carry a typed value.
  # Use this for Matter fields whose absent and Null forms have different
  # meanings. Plain `T?` fields keep their existing behavior.
  struct FieldState(T)
    enum Kind
      Absent
      Null
      Value
    end

    getter kind : Kind

    private def initialize(@kind : Kind, @value : T? = nil)
    end

    def self.absent : self
      new(Kind::Absent)
    end

    def self.null : self
      new(Kind::Null)
    end

    def self.value(value : T) : self
      new(Kind::Value, value)
    end

    def absent? : Bool
      @kind.absent?
    end

    def null? : Bool
      @kind.null?
    end

    def value? : Bool
      @kind.value?
    end

    def value! : T
      raise ArgumentError.new("TLV field does not contain a value") unless value?
      @value.as(T)
    end
  end
end
