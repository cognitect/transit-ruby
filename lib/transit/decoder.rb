require 'uri'
require 'json'

module Transit
  class Decoder
    NOT_FOUND = Object.new
    ALWAYS_NOT_FOUND = ->(v){NOT_FOUND}

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
        "~c"  => ->(s){Char.new(s[2..-1])},              # char
        "~$"  => ->(s){TransitSymbol.new(s[2..-1])},
        "~t"  => ->(s){Time.parse(s[2..-1])},
        "~u"  => ->(s){UUID.new(s[2..-1])},
        "~r"  => ->(s){URI(s[2..-1])},
        "~#t" => method(:decode_instant),
        "~#set" =>  method(:decode_set),
        "~#list" => method(:decode_list),
        "~#ints" => method(:decode_ints),
        "~#longs" => method(:decode_longs),
        "~#floats" => method(:decode_floats),
        "~#doubles" => method(:decode_doubles),
        "~#bools" => method(:decode_bools)
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
      TransitList.new(m.values.first.map {|v| decode(v)})
    end

    def decode_instant(m)
      Time.parse(m.values.first).utc
    end

    def decode_typed_array(type, m)
      TypedArray.new(type, decode(m.values.first))
    end

    def decode_ints(m)
      decode_typed_array("ints", m)
    end

    def decode_longs(m)
      decode_typed_array("longs", m)
    end

    def decode_floats(m)
      decode_typed_array("floats", m)
    end

    def decode_doubles(m)
      decode_typed_array("doubles", m)
    end

    def decode_bools(m)
      decode_typed_array("bools", m)
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
