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

    def to_s
      @value
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
    def initialize(ary)
      super ary
    end

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

  class Char < Wrapper
    def initialize(c)
      raise ArgumentError.new("Char can only contain one character.") if c.length > 1
      super c
    end

    def to_s
      @value
    end
  end

  class CMap < Wrapper
    def initialize(m)
      super m
    end

    def to_a
      # TODO benchmark this against @value.to_a.flatten(1)
      @value.reduce([]) {|a, kv| a.concat(kv)}
    end
  end
end
