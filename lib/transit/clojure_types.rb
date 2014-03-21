require 'base64'
require 'securerandom'
require 'forwardable'

module Transit
  class Wrapper
    extend Forwardable

    def_delegators :@value, :hash, :to_sym, :to_s

    def initialize(value)
      @value = value
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      to_sym == other.to_sym
    end

    def eql?(other)
      return false unless other.is_a?(self.class)
      to_sym == other.to_sym
    end
  end

  class ClojureSymbol < Wrapper
    def initialize(sym)
      super sym.to_sym
    end
  end

  class UUID < String
    def initialize(uuid=SecureRandom.uuid)
      super uuid
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
end
