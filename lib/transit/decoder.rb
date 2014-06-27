# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class Decoder
    ESC_ESC  = "#{ESC}#{ESC}"
    ESC_SUB  = "#{ESC}#{SUB}"
    ESC_RES  = "#{ESC}#{RES}"

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
          "n" => ->(v){v.to_i},
          "c" => IDENTITY,
          "$" => ->(v){TransitSymbol.new(v)},
          "t" => ->(v){DateTime.iso8601(v)},
          "m" => ->(v){DateTimeUtil.from_millis(v.to_i)},
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
        :default_decoder => ->(tag,val){TaggedValue.new(tag, val)}
      }
    end

    def decode(node, cache=RollingCache.new, as_map_key=false)
      case node
      when String
        decode_string(node, cache, as_map_key)
      when Hash
        decode_hash(node, cache, as_map_key)
      when Array
        if node[0] == MAP_AS_ARRAY
          decode_hash(Hash[*node.drop(1)], cache, as_map_key)
        else
          node.map! {|n| decode(n, cache, as_map_key)}
        end
      else
        node
      end
    end

    def decode_hash(hash, cache, as_map_key)
      if hash.size == 1
        k = decode(hash.keys.first,   cache, true)
        v = decode(hash.values.first, cache, false)
        if String === k && k.start_with?(TAG)
          tag = k[2..-1]
          if decoder = @decoders[tag]
            decoder.call(v)
          else
            @options[:default_decoder].call(tag,v)
          end
        else
          {k => v}
        end
      else
        hash.keys.each do |k|
          hash.store(decode(k, cache, true), decode(hash.delete(k), cache))
        end
        hash
      end
    end

    def decode_string(string, cache, as_map_key)
      if cache.has_key?(string)
        cache.read(string)
      else
        parsed = begin
                   if !string.start_with?(ESC) || string.start_with?(TAG)
                     string
                   elsif decoder = @decoders[string[1]]
                     decoder.call(string[2..-1])
                   elsif string.start_with?(ESC_ESC, ESC_SUB, ESC_RES)
                     string[1..-1]
                   else
                     @options[:default_decoder].call(string[1], string[2..-1])
                   end
                 end
        cache.write(parsed) if cache.cacheable?(string, as_map_key)
        parsed
      end
    end

    def register(tag_or_key, &b)
      if tag_or_key == :default_decoder
        raise ArgumentError.new(DEFAULT_DECODER_ARITY_MESSAGE) unless b.arity == 2
        @options[:default_decoder] = b
      else
        raise ArgumentError.new(TYPE_DECODER_ARITY_MESSAGE) unless b.arity == 1
        @decoders[tag_or_key] = b
      end
    end

    TYPE_DECODER_ARITY_MESSAGE = <<-MSG
Custom type-specific decoder functions require arity 1
- the string or hash to decode
MSG

    DEFAULT_DECODER_ARITY_MESSAGE = <<-MSG
Default decoder functions require arity 2
- the tag and the value
MSG

  end
end
