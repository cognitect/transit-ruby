require 'uri'
require 'json'

module Transit
  class Decoder
    def initialize(options={})
      options = default_options.merge(options)
      @decoders = options[:decoders]
    end

    def default_options
      {decoders: {
          "~~" => method(:decode_escaped_string),
          "~:" => method(:decode_keyword),
          "~b" => method(:decode_byte_array),
          "~d" => method(:decode_float),
          "~f" => method(:decode_big_decimal),
          "~c" => method(:decode_char),
          "~$" => method(:decode_transit_symbol),
          "~t" => method(:decode_instant),
          "~u" => method(:decode_uuid),
          "~r" => method(:decode_uri),
          "~#'"       => method(:decode),
          "~#t"       => method(:decode_instant),
          "~#set"     => method(:decode_set),
          "~#list"    => method(:decode_list),
          "~#ints"    => method(:decode_ints),
          "~#longs"   => method(:decode_longs),
          "~#floats"  => method(:decode_floats),
          "~#doubles" => method(:decode_doubles),
          "~#bools"   => method(:decode_bools)
        }}
    end

    def decode(node)
      case node
      when String
        decode_string(node)
      when Hash
        decode_hash(node)
      when Array
        node.map {|n| decode(n)}
      else
        node
      end
    end

    def decode_hash(hash)
      if decoder = @decoders[hash.keys.first]
        decoder.call(hash.values.first)
      else
        hash.reduce({}) { |h,kv| h.store(decode(kv[0]), decode(kv[1])); h}
      end
    end

    def decode_string(string)
      if decoder = @decoders[string[0..1]]
        decoder.call(string[2..-1])
      else
        string
      end
    end

    def decode_escaped_string(s)
      # Hack alert - this is actually restoring the escaped "~"
      # which was stripped in decode_string. It's either that or
      # make every one of these methods responsible for destructuring
      # strings.
      "~#{s}"
    end

    def decode_uri(s)
      URI(s)
    end

    def decode_keyword(s)
      s.to_sym
    end

    def decode_byte_array(s)
      ByteArray.from_base64(s)
    end

    def decode_float(s)
      Float(s)
    end

    def decode_big_decimal(s)
      BigDecimal.new(s)
    end

    def decode_char(s)
      Char.new(s)
    end

    def decode_transit_symbol(s)
      TransitSymbol.new(s)
    end

    def decode_set(m)
      Set.new(m.map {|v| decode(v)})
    end

    def decode_list(m)
      TransitList.new(m.map {|v| decode(v)})
    end

    def decode_instant(m)
      Time.parse(m).utc
    end

    def decode_uuid(s)
      UUID.new(s)
    end

    def decode_typed_array(type, m)
      TypedArray.new(type, decode(m))
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
