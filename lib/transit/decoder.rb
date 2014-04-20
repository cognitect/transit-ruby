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
          "#{ESC}_" => method(:decode_nil),
          "#{ESC}:" => method(:decode_keyword),
          "#{ESC}?" => method(:decode_bool),
          "#{ESC}b" => method(:decode_byte_array),
          "#{ESC}d" => method(:decode_float),
          "#{ESC}i" => method(:decode_int),
          "#{ESC}f" => method(:decode_big_decimal),
          "#{ESC}c" => method(:decode_char),
          "#{ESC}$" => method(:decode_transit_symbol),
          "#{ESC}t" => method(:decode_instant_from_string),
          "#{ESC}u" => method(:decode_uuid),
          "#{ESC}r" => method(:decode_uri),
          "#{TAG}'"       => method(:decode_quote),
          "#{TAG}t"       => method(:decode_instant_from_int),
          "#{TAG}u"       => method(:decode_uuid),
          "#{TAG}set"     => method(:decode_set),
          "#{TAG}list"    => method(:decode_list),
          "#{TAG}ints"    => method(:decode_ints),
          "#{TAG}longs"   => method(:decode_longs),
          "#{TAG}floats"  => method(:decode_floats),
          "#{TAG}doubles" => method(:decode_doubles),
          "#{TAG}bools"   => method(:decode_bools),
          "#{TAG}cmap"    => method(:decode_cmap)
        }}
    end

    def decode(node, cache=RollingCache.new, as_map_key=false)
      case node
      when String
        decode_string(node, cache, as_map_key)
      when Hash
        decode_hash(node, cache, as_map_key)
      when Array
        node.map {|n| decode(n, cache, as_map_key)}
      else
        node
      end
    end

    def decode_hash(hash, cache, as_map_key)
      if hash.size == 1
        key = decode(hash.keys.first, cache, true)
        if decoder = @decoders[key]
          return decoder.call(decode(hash.values.first, cache, false), cache, as_map_key)
        elsif String === key && /^~#/ =~ key
          return TaggedValue.new(key, decode(hash.values.first, cache, false))
        end
      end
      hash.reduce({}) {|h,kv| h.store(decode(kv[0], cache, true), decode(kv[1], cache)); h}
    end

    def decode_string(string, cache, as_map_key)
      if cache.cacheable?(string, as_map_key)
        cache.encode(string, as_map_key)
        parse_string(string, cache, as_map_key)
      elsif cache.cache_key?(string)
        parse_string(cache.decode(string, as_map_key), cache, as_map_key)
      else
        parse_string(string, cache, as_map_key)
      end
    end

    ESCAPED_ESC = Regexp.escape(ESC)
    ESCAPED_SUB = Regexp.escape(SUB)
    ESCAPED_RES = Regexp.escape(RES)
    IS_ESCAPED  = Regexp.new("^#{ESCAPED_ESC}(#{ESCAPED_SUB}|#{ESCAPED_ESC}|#{ESCAPED_RES})")

    def parse_string(str, cache, as_map_key)
      if IS_ESCAPED =~ str
        str[1..-1]
      elsif decoder = @decoders[str[0..1]]
        decoder.call(str[2..-1], cache, as_map_key)
      elsif /^~\w/ =~ str
        "`#{str}"
      else
        str
      end
    end

    def decode_quote(n, _, _)
      n
    end

    def decode_nil(n, cache, as_map_key)
      nil
    end

    def decode_bool(b, cache, as_map_key)
      b == "t"
    end

    def decode_uri(s, cache, as_map_key)
      URI(s)
    end

    def decode_keyword(s, cache, as_map_key)
      s.to_sym
    end

    def decode_byte_array(s, cache, as_map_key)
      ByteArray.from_base64(s)
    end

    def decode_float(s, cache, as_map_key)
      Float(s)
    end

    def decode_int(s, cache, as_map_key)
      s.to_i
    end

    def decode_big_decimal(s, cache, as_map_key)
      BigDecimal.new(s)
    end

    def decode_char(s, cache, as_map_key)
      Char.new(s)
    end

    def decode_transit_symbol(s, cache, as_map_key)
      TransitSymbol.new(s)
    end

    def decode_set(m, cache, as_map_key)
      Set.new(decode(m, cache, as_map_key))
    end

    def decode_list(m, cache, as_map_key)
      TransitList.new(decode(m, cache, as_map_key))
    end

    def decode_instant_from_string(s, cache, as_map_key)
      # s is already in zulu time, so no need to convert
      DateTime.iso8601(s)
    end

    def decode_instant_from_int(i, cache, as_key)
      Util.date_time_from_millis(i).new_offset(0)
    end

    def decode_uuid(rep, cache, as_map_key)
      UUID.new(rep)
    end

    def decode_ints(m, cache, as_map_key)
      IntsArray.new(decode(m, cache, as_map_key))
    end

    def decode_longs(m, cache, as_map_key)
      LongsArray.new(decode(m, cache, as_map_key))
    end

    def decode_floats(m, cache, as_map_key)
      FloatsArray.new(decode(m, cache, as_map_key))
    end

    def decode_doubles(m, cache, as_map_key)
      DoublesArray.new(decode(m, cache, as_map_key))
    end

    def decode_bools(m, cache, as_map_key)
      BoolsArray.new(decode(m, cache, as_map_key))
    end

    def decode_cmap(v, cache, as_map_key)
      decode(Hash[*v], cache, as_map_key)
    end

    def register(k, &b)
      raise ArgumentError.new(DECODER_ARITY_MESSAGE) unless b.arity == 1
      @decoders["~#{k}"] = b if k.length == 1
      @decoders["~##{k}"] = b
    end

    DECODER_ARITY_MESSAGE = <<-MSG
Decoder functions require arity 1
- the string to decode
MSG
  end
end
