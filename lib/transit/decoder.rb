require 'uri'
require 'json'

module Transit
  class Decoder
    def initialize(handlers=Handler.new)
      @decoders = handlers.handlers.reduce({}) do |m,h|
        "#{ESC}#{h.tag}".tap {|k| m[k] = h}
        "#{TAG}#{h.tag}".tap {|k| m[k] = h}
        m
      end
    end

    def decode(node, cache, as_map_key=false)
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

    def find_encoded_hash_decoder(hash, cache)
      return nil unless hash.size == 1
      key = decode(hash.keys.first, cache, true)
      @decoders[key]
    end

    def decode_hash(hash, cache, as_map_key)
      if decoder = find_encoded_hash_decoder(hash, cache)
        if decoder.respond_to?(:build)
          decoder.build(decode(hash.values.first, cache, as_map_key))
        else
          decoder.call(hash.values.first, cache, as_map_key)
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
        if decoder.respond_to?(:build)
          decoder.build(str[2..-1])
        else
          decoder.call(str[2..-1], cache, as_map_key)
        end
      else
        str
      end
    end
  end
end
