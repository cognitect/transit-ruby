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
          "#{ESC}_" => ->(_){nil},
          "#{ESC}:" => ->(v){v.to_sym},
          "#{ESC}?" => ->(v){v == "t"},
          "#{ESC}b" => ->(v){ByteArray.from_base64(v)},
          "#{ESC}d" => ->(v){Float(v)},
          "#{ESC}i" => ->(v){v.to_i},
          "#{ESC}f" => ->(v){BigDecimal.new(v)},
          "#{ESC}c" => ->(v){Char.new(v)},
          "#{ESC}$" => ->(v){TransitSymbol.new(v)},
          "#{ESC}t" => ->(v){DateTime.iso8601(v)},
          "#{ESC}u" => ->(v){UUID.new(v)},
          "#{ESC}r" => ->(v){URI(v)},
          "#{TAG}'"       => ->(v){v},
          "#{TAG}t"       => ->(v){Util.date_time_from_millis(v).new_offset(0)},
          "#{TAG}u"       => ->(v){UUID.new(v)},
          "#{TAG}set"     => ->(v){Set.new(v)},
          "#{TAG}list"    => ->(v){TransitList.new(v)},
          "#{TAG}ints"    => ->(v){IntsArray.new(v)},
          "#{TAG}longs"   => ->(v){LongsArray.new(v)},
          "#{TAG}floats"  => ->(v){FloatsArray.new(v)},
          "#{TAG}doubles" => ->(v){DoublesArray.new(v)},
          "#{TAG}bools"   => ->(v){BoolsArray.new(v)},
          "#{TAG}cmap"    => ->(v){Hash[*v]}
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
          return decoder.call(decode(hash.values.first, cache, false))
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
        decoder.call(str[2..-1])
      elsif /^~\w/ =~ str
        "`#{str}"
      else
        str
      end
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
