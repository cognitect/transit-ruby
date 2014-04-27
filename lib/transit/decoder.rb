module Transit
  class Decoder
    IDENTITY = ->(v){v}

    def initialize(options={})
      @options = default_options.merge(options)
      @decoders = @options[:decoders]
    end

    def default_options
      {decoders: {
          "_" => ->(_){nil},
          ":" => ->(v){v.to_sym},
          "?" => ->(v){v == "t"},
          "b" => ->(v){ByteArray.from_base64(v)},
          "d" => ->(v){Float(v)},
          "i" => ->(v){v.to_i},
          "f" => ->(v){BigDecimal.new(v)},
          "c" => IDENTITY,
          "$" => ->(v){TransitSymbol.new(v)},
          "t" => ->(v){String === v ? DateTime.iso8601(v) : DateTimeUtil.from_millis(v)},
          "u" => ->(v){UUID.new(v)},
          "r" => ->(v){Addressable::URI.parse(v)},
          "'" => ->(v){v},
          "set"     => ->(v){Set.new(v)},
          "list"    => IDENTITY,
          "ints"    => IDENTITY,
          "longs"   => IDENTITY,
          "floats"  => IDENTITY,
          "doubles" => IDENTITY,
          "bools"   => IDENTITY,
          "cmap"    => ->(v){Hash[*v]}
        },
        :default_string_decoder => ->(s){"`#{s}"},
        :default_hash_decoder   => ->(h){TaggedValue.new(h.keys.first, h.values.first)}
      }
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
        if String === key && /^#{TAG}/ =~ key
          if decoder = @decoders[key[2..-1]]
            decoder.call(decode(hash.values.first, cache, false))
          else
            @options[:default_hash_decoder].call({key => decode(hash.values.first, cache, false)})
          end
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
        decode(cache.decode(string, as_map_key), cache, as_map_key)
      else
        parse_string(string, cache, as_map_key)
      end
    end

    def parse_string(str, cache, as_map_key)
      if /^#{ESC}/ =~ str
        case str[1]
        when ESC,SUB,RES then str[1..-1]
        when "#" then str
        else
          if decoder = @decoders[str[1]]
            decoder.call(str[2..-1])
          else
            @options[:default_string_decoder].call(str)
          end
        end
      else
        str
      end
    end

    def register(tag_or_key, &b)
      raise ArgumentError.new(DECODER_ARITY_MESSAGE) unless b.arity == 1
      if tag_or_key == :default_string_decoder
        @options[:default_string_decoder] = b
      elsif tag_or_key == :default_hash_decoder
        @options[:default_hash_decoder] = b
      else
        @decoders[tag_or_key] = b
      end
    end

    DECODER_ARITY_MESSAGE = <<-MSG
Decoder functions require arity 1
- the string or hash to decode
MSG

  end
end
