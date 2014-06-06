# Copyright (c) Cognitect, Inc.
# All rights reserved.

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

    def hash
      @value.hash
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
    attr_reader :most_significant_bits, :least_significant_bits

    def initialize(uuid_or_most_significant_bits=nil,least_significant_bits=nil)
      case uuid_or_most_significant_bits
      when String
        @most_significant_bits, @least_significant_bits = parse_msb_lsb(uuid_or_most_significant_bits)
        super uuid_or_most_significant_bits
      when Numeric
        @most_significant_bits, @least_significant_bits = twos_complement(uuid_or_most_significant_bits), twos_complement(least_significant_bits)
        super to_s
      when Array
        @most_significant_bits, @least_significant_bits = uuid_or_most_significant_bits.map{|i| twos_complement(i) }
        super to_s
      when nil
        super SecureRandom.uuid
        @most_significant_bits, @least_significant_bits = parse_msb_lsb(@value)
      else
        raise "Can't build UUID from #{uuid_or_most_significant_bits.inspect}"
      end
    end

    def self.random
      new
    end

    def to_s
      @value ||= digits(@most_significant_bits >> 32, 8) + "-" +
        digits(@most_significant_bits >> 16, 4) + "-" +
        digits(@most_significant_bits, 4)       + "-" +
        digits(@least_significant_bits >> 48, 4) + "-" +
        digits(@least_significant_bits, 12)
    end

    def inspect
      "<#{self.class} \"#{to_s}\">"
    end

    private

    def digits(val, digits)
      hi = 1 << (digits*4)
      (hi | (val & (hi - 1))).to_s(16)[1..-1]
    end

    def twos_complement(integer_value, num_of_bits=64)
      max_signed   = 2**(num_of_bits-1)
      max_unsigned = 2**num_of_bits
      (integer_value >= max_signed) ? integer_value - max_unsigned : integer_value
    end

    def parse_msb_lsb(s)
      str = s.delete("-")
      msb = str[0..15]
      lsb = str[16..31]
      [twos_complement(msb.hex), twos_complement(lsb.hex)]
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

  class TaggedValue
    attr_reader :tag, :value
    def initialize(tag, value)
      @tag   = tag
      @value = value
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      other.tag == @tag && other.value == @value
    end

    def eql?(other)
      return false unless other.is_a?(self.class)
      other.tag.eql?(@tag) && other.value.eql?(@value)
    end

    def hash
      @tag.hash + @value.hash
    end
  end
end
