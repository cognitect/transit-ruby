require 'uri'
require 'set'

module Transit
  class ClassHash
    extend Forwardable

    def_delegators :@values, :[]=, :size, :each

    def initialize
      @values = {}
    end

    def [](clazz)
      return nil unless clazz
      value = @values[clazz]
      value ? value : self[clazz.superclass]
    end
  end


  class Encoder
    IDENTITY = ->(v){v}

    def initialize
      @encoders = ClassHash.new
      init_default_encoders
    end

    def encode(obj)
      @encoders[obj.class].call(obj)
    end

    def encode_as_key(obj)
      encode(obj)  # TBD need to do special stuff for keys
    end

    def register(clazz, &block)
      raise "Register requires a one argument block." unless block.arity == 1
      @encoders[clazz] = block
    end

    private

    def init_default_encoders
      register(Symbol) {|s| "~:#{s}"}
      register(TransitSymbol) {|s| "~'#{s}"}
      register(String) {|s| s.sub(/^~/, '~~')}
      register(Fixnum, &IDENTITY)
      register(NilClass, &IDENTITY)
      register(TrueClass, &IDENTITY)
      register(FalseClass, &IDENTITY)
      register(Float, &IDENTITY)
      register(Bignum) {|n| {'#i' => n}}
      register(BigDecimal) {|n| "~f#{n.to_f}"}
      register(ByteArray) {|ba| "~b#{ba.to_base64}"}
      register(URI) {|uri| "~r#{uri}"}
    end
  end

  class JsonEncoder < Encoder
    def initialize
      super
      register(Time) {|t| "~t#{t.strftime("%FT%H:%M:%S.%LZ")}" }
      register(UUID) {|uuid| "~u#{uuid.to_s}"}
    end
  end

  class MessagePackEncoder < Encoder
    def initialize
      super
      register(Time) {|t| {'~#t' => t.strftime("%FT%H:%M:%S.%LZ")}}
      register(UUID) {|uuid| {'~#u' => uuid.to_s}}
    end
  end
end
