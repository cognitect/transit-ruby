require 'uri'
require 'json'

module Transit
  class Decoder
    def initialize(options={})
      @options = default_options.merge(options)
      @decoders = @options[:decoders]
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
          "#{ESC}r" => ->(v){Addressable::URI.parse(v)},
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
        if decoder = @decoders[key]
          return decoder.call(decode(hash.values.first, cache, false))
        elsif String === key && /^~#/ =~ key
          @options[:default_hash_decoder].call({key => decode(hash.values.first, cache, false)})
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
    IS_UNRECOGNIZED = /^#{ESC}\w/

    def parse_string(str, cache, as_map_key)
      if IS_ESCAPED =~ str
        str[1..-1]
      elsif decoder = @decoders[str[0..1]]
        decoder.call(str[2..-1])
      elsif IS_UNRECOGNIZED =~ str
        @options[:default_string_decoder].call(str)
      else
        str
      end
    end

    def register(tag_or_key, type=nil, &b)
      raise ArgumentError.new(DECODER_ARITY_MESSAGE) unless b.arity == 1
      raise ArgumentError.new(TAG_LENGTH_MESSAGE) if type == :string && tag_or_key.length > 1
      if tag_or_key == :default_string_decoder
        @options[:default_string_decoder] = b
      elsif tag_or_key == :default_hash_decoder
        @options[:default_hash_decoder] = b
      else
        @decoders["~##{tag_or_key}"] = b if type.nil? or type == :hash
        @decoders["~#{tag_or_key}"] = b  if (type.nil? or type == :string) && tag_or_key.length == 1
      end
    end

    DECODER_ARITY_MESSAGE = <<-MSG
Decoder functions require arity 1
- the string or hash to decode
MSG

    TAG_LENGTH_MESSAGE = <<-MSG
Tags for string decoders must be one character.
MSG
  end
end
