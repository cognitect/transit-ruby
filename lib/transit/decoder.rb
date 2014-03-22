require 'uri'

module Transit
  class Decoder
    NOT_FOUND = Object.new
    ALWAYS_NOT_FOUND = ->(v){NOT_FOUND}
    TRANSPORT = :json

    IDENTITY   = ->(v){v}
    ALWAYS_NIL = ->(_){ }

    def initialize(options={})
      options = default_options.merge(options)
      @decoders = options[:decoders]
    end

    def default_options
      default_decoders = {
        "~~"  => ->(s){s[1..-1]},                        # escaped string
        "~:"  => ->(s){s[2..-1].to_sym},                 # keyword
        "~b"  => ->(s){ByteArray.from_base64(s[2..-1])},
        "~d"  => ->(s){Float(s[2..-1])},
        "~f"  => ->(s){BigDecimal.new(s[2..-1])},
        "~c"  => ->(s){s[2..-1]},                        # char
        "~'"  => ->(s){ClojureSymbol.new(s[2..-1])},
        "~t"  => ->(s){Time.parse(s[2..-1]).utc},
        "~u"  => ->(s){UUID.new(s[2..-1])},
        "~r"  => ->(s){URI(s[2..-1])},
        "~#s" => method(:decode_set),
        "~#(" => method(:decode_list),
        "~#t" => method(:decode_instant),
      }

      {decoders: default_decoders}
    end

    def decode(node)
      case node
      when String
        decode_string(node)
      when Hash
        if (result = decode_encoded_hash(node)) == NOT_FOUND
          decode_hash(node)
        else
          result
        end
      when Array
        node.map {|n| decode(n)}
      else
        node
      end
    end

    def decode_encoded_hash(hash)
      @decoders.fetch(hash.keys.first, ALWAYS_NOT_FOUND).call(hash)
    end

    def decode_hash(hash)
      hash.reduce({}) do |h,kv|
        h.store(decode(kv[0]), decode(kv[1]))
        h
      end
    end

    def decode_string(string)
      @decoders.fetch(string[0..1], IDENTITY).call(string)
    end

    def decode_set(m)
      Set.new(m.values.first.map {|v| decode(v)})
    end

    def decode_list(m)
      m.values.first.map {|v| decode(v)}
    end

    def decode_instant(m)
      Time.parse(m.values.first).utc
    end

    def register(k, &b)
      raise ArgumentError.new(DECODER_ARITY_MESSAGE) unless b.arity == 1
      @decoders[k] = b
    end

    DECODER_ARITY_MESSAGE = <<-MSG
Decoder functions require arity 1
- the string to decode
MSG
  end
end
