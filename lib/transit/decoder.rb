# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  # Converts a transit value to an instance of a type
  class Decoder
    ESC_ESC  = "#{ESC}#{ESC}"
    ESC_SUB  = "#{ESC}#{SUB}"
    ESC_RES  = "#{ESC}#{RES}"

    IDENTITY = ->(v){v}

    DEFAULT_DECODERS = {
      "_" => ->(_){nil},
      ":" => ->(v){v.to_sym},
      "?" => ->(v){v == "t"},
      "b" => ->(v){ByteArray.from_base64(v)},
      "d" => ->(v){Float(v)},
      "i" => ->(v){v.to_i},
      "n" => ->(v){v.to_i},
      "f" => ->(v){BigDecimal.new(v)},
      "c" => IDENTITY,
      "$" => ->(v){Transit::Symbol.new(v)},
      "t" => ->(v){DateTime.iso8601(v)},
      "m" => ->(v){DateTimeUtil.from_millis(v.to_i)},
      "u" => ->(v){UUID.new(v)},
      "r" => ->(v){Addressable::URI.parse(v)},
      "'" => ->(v){v},
      "set"     => ->(v){Set.new(v)},
      "link"    => ->(v){Link.new(v)},
      "list"    => IDENTITY,
      "ints"    => IDENTITY,
      "longs"   => IDENTITY,
      "floats"  => IDENTITY,
      "doubles" => IDENTITY,
      "bools"   => IDENTITY,
      "cmap"    => ->(v){Hash[*v]}
    }.freeze

    DEFAULT_DECODER = ->(tag,val){TaggedValue.new(tag, val)}

    def initialize(options={})
      custom_decoders = options[:decoders] || {}
      custom_decoders.each {|k,v| validate_decoder(k,v)}
      @decoders = DEFAULT_DECODERS.merge(custom_decoders)

      validate_default_decoder(options[:default_decoder]) if options[:default_decoder]
      @default_decoder = options[:default_decoder] || DEFAULT_DECODER
    end

    # Decodes a transit value to a corresponding object
    #
    # @param node a transit value to be decoded
    # @param cache
    # @param as_map_key
    # @return decoded object
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
            @default_decoder.call(tag,v)
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
                     @default_decoder.call(string[1], string[2..-1])
                   end
                 end
        cache.write(parsed) if cache.cacheable?(string, as_map_key)
        parsed
      end
    end

    GROUND_TAGS = %w[- s ? i d b ' array map]

    def validate_decoder(key, decoder)
      raise ArgumentError.new(CAN_NOT_OVERRIDE_GROUND_TYPES_MESSAGE) if GROUND_TAGS.include?(key)
      raise ArgumentError.new(TYPE_DECODER_ARITY_MESSAGE) unless decoder.arity == 1
    end

    def validate_default_decoder(decoder)
      raise ArgumentError.new(DEFAULT_DECODER_ARITY_MESSAGE) unless decoder.arity == 2
    end

    CAN_NOT_OVERRIDE_GROUND_TYPES_MESSAGE = <<-MSG
You can not supply custom decoders for ground types.
MSG

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
