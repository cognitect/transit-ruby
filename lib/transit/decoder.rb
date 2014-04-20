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
        else
          {key => decode(hash.values.first, cache, false)}
        end
      else
        hash.reduce({}) {|h,kv| h.store(decode(kv[0], cache, true), decode(kv[1], cache)); h}
      end
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

    def decode_quote(v,_,_)
      v
    end

    def decode_nil(_,_,_)
      nil
    end

    def decode_bool(v,_,_)
      v == "t"
    end

    def decode_uri(v,_,_)
      URI(v)
    end

    def decode_keyword(v,_,_)
      v.to_sym
    end

    def decode_byte_array(v,_,_)
      ByteArray.from_base64(v)
    end

    def decode_float(v,_,_)
      Float(v)
    end

    def decode_int(v,_,_)
      v.to_i
    end

    def decode_big_decimal(v,_,_)
      BigDecimal.new(v)
    end

    def decode_char(v,_,_)
      Char.new(v)
    end

    def decode_transit_symbol(v,_,_)
      TransitSymbol.new(v)
    end

    def decode_set(v,_,_)
      Set.new(v)
    end

    def decode_list(v,_,_)
      TransitList.new(v)
    end

    def decode_instant_from_string(v,_,_)
      # s is already in zulu time, so no need to convert
      DateTime.iso8601(v)
    end

    def decode_instant_from_int(v,_,_)
      Util.date_time_from_millis(v).new_offset(0)
    end

    def decode_uuid(rep,_,_)
      UUID.new(rep)
    end

    def decode_ints(v,_,_)
      IntsArray.new(v)
    end

    def decode_longs(v,_,_)
      LongsArray.new(v)
    end

    def decode_floats(v,_,_)
      FloatsArray.new(v)
    end

    def decode_doubles(v,_,_)
      DoublesArray.new(v)
    end

    def decode_bools(v,_,_)
      BoolsArray.new(v)
    end

    def decode_cmap(v, _, _)
      Hash[*v]
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
