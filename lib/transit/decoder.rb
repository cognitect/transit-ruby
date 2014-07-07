# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  # Converts a transit value to an instance of a type
  # @api private
  class Decoder
    ESC_ESC  = "#{ESC}#{ESC}"
    ESC_SUB  = "#{ESC}#{SUB}"
    ESC_RES  = "#{ESC}#{RES}"

    IDENTITY = ->(v){v}

    GROUND_TAGS = %w[_ s ? i d b ' array map]

    DEFAULT_READ_HANDLERS = {
      "_" => ReadHandlers::NilHandler.new,
      ":" => ReadHandlers::KeywordHandler.new,
      "?" => ReadHandlers::BooleanHandler.new,
      "b" => ReadHandlers::ByteArrayHandler.new,
      "d" => ReadHandlers::FloatHandler.new,
      "i" => ReadHandlers::IntegerHandler.new,
      "n" => ReadHandlers::BigIntegerHandler.new,
      "f" => ReadHandlers::BigDecimalHandler.new,
      "c" => ReadHandlers::IdentityHandler.new,
      "$" => ReadHandlers::SymbolHandler.new,
      "t" => ReadHandlers::TimeStringHandler.new,
      "m" => ReadHandlers::TimeIntHandler.new,
      "u" => ReadHandlers::UuidHandler.new,
      "r" => ReadHandlers::UriHandler.new,
      "'" => ReadHandlers::IdentityHandler.new,
      "set"     => ReadHandlers::SetHandler.new,
      "link"    => ReadHandlers::LinkHandler.new,
      "list"    => ReadHandlers::IdentityHandler.new,
      "ints"    => ReadHandlers::IdentityHandler.new,
      "longs"   => ReadHandlers::IdentityHandler.new,
      "floats"  => ReadHandlers::IdentityHandler.new,
      "doubles" => ReadHandlers::IdentityHandler.new,
      "bools"   => ReadHandlers::IdentityHandler.new,
      "cmap"    => ReadHandlers::CmapHandler.new
    }.freeze

    DEFAULT_READ_HANDLER = ReadHandlers::Default.new

    def initialize(options={})
      custom_handlers = options[:handlers] || {}
      custom_handlers.each {|k,v| validate_handler(k,v)}
      @handlers = DEFAULT_READ_HANDLERS.merge(custom_handlers)
      @default_handler = options[:default_handler] || DEFAULT_READ_HANDLER
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
          if handler = @handlers[tag]
            handler.from_rep(v)
          else
            @default_handler.from_rep(tag,v)
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
                   elsif handler = @handlers[string[1]]
                     handler.from_rep(string[2..-1])
                   elsif string.start_with?(ESC_ESC, ESC_SUB, ESC_RES)
                     string[1..-1]
                   else
                     @default_handler.from_rep(string[1], string[2..-1])
                   end
                 end
        cache.write(parsed) if cache.cacheable?(string, as_map_key)
        parsed
      end
    end

    def validate_handler(key, handler)
      raise ArgumentError.new(CAN_NOT_OVERRIDE_GROUND_TYPES_MESSAGE) if GROUND_TAGS.include?(key)
    end

    CAN_NOT_OVERRIDE_GROUND_TYPES_MESSAGE = <<-MSG
You can not supply custom handlers for ground types.
MSG

  end
end
