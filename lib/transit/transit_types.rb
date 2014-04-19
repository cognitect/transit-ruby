require 'base64'
require 'securerandom'
require 'forwardable'

module Transit
  class Wrapper
    extend Forwardable

    def_delegators :@value, :hash, :to_sym, :to_s

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      @value == other.value
    end

    def eql?(other)
      return false unless other.is_a?(self.class)
      @value.eql?(other.value)
    end

    def inspect
      "<#{self.class} \"#{to_s}\">"
    end
  end

  class TransitSymbol < Wrapper
    def initialize(sym)
      super sym.to_sym
    end
  end

  class UUID < Wrapper
    def initialize(uuid=SecureRandom.uuid)
      super uuid
    end

    def self.random
      new
    end

    def self.from_string(s)
      new(s)
    end

    def self.from_ints(b)
      new(digits(b[0] >> 32, 8) + "-" +
          digits(b[0] >> 16, 4) + "-" +
          digits(b[0], 4)       + "-" +
          digits(b[1] >> 48, 4) + "-" +
          digits(b[1], 12))
    end

    def as_ints
      @as_ints ||= to_ints(@value)
    end

    def to_s
      @value
    end

    def inspect
      "<#{self.class} \"#{to_s}\">"
    end

    private

    def self.digits(val, digits)
      hi = 1 << (digits*4)
      (hi | (val & (hi - 1))).to_s(16)[1..-1]
    end

    def to_ints(s)
      components = s.split("-")
      raise ArgumentError.new("Invalid UUID string: #{s}") unless components.size == 5
      msb = components[0].hex
      msb = msb << 16
      msb = msb | components[1].hex
      msb = msb << 16
      msb = msb | components[2].hex

      lsb = components[3].hex
      lsb = lsb << 48
      lsb = lsb | components[4].hex

      return msb, lsb
    end
  end

  class ByteArray < Wrapper
    def self.from_base64(data)
      new(Base64.decode64(data))
    end

    def to_base64
      Base64.encode64(@value)
    end

    def to_s
      @value
    end
  end

  class TransitList < Wrapper
    def to_a
      @value
    end
  end

  class TypedArray < Wrapper
    def initialize(t, ary)
      @type = t
      super ary
    end

    def type
      @type.to_s
    end

    def to_a
      @value
    end
  end

  class IntsArray < TypedArray
    def initialize(ary)
      super("ints", ary)
    end
  end

  class LongsArray < TypedArray
    def initialize(ary)
      super("longs", ary)
    end
  end

  class DoublesArray < TypedArray
    def initialize(ary)
      super("doubles", ary)
    end
  end

  class FloatsArray < TypedArray
    def initialize(ary)
      super("floats", ary)
    end
  end

  class BoolsArray < TypedArray
    def initialize(ary)
      super("bools", ary)
    end
  end

  class Char < Wrapper
    def initialize(c)
      raise ArgumentError.new("Char can only contain one character.") if c.length > 1
      super c
    end

    def to_s
      @value
    end
  end

  class Quote < Wrapper; end
end
