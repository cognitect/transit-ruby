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

    def initialize(options={})
      custom_handlers = options[:handlers] || {}
      custom_handlers.each {|k,v| validate_handler(k,v)}
      @handlers = Reader::DEFAULT_READ_HANDLERS.merge(custom_handlers)
      @default_handler = options[:default_handler] || Reader::DEFAULT_READ_HANDLER
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
        if cache.has_key?(node)
          cache.read(node)
        else
          parsed = begin
                     if !node.start_with?(ESC) || node.start_with?(TAG)
                       node
                     elsif handler = @handlers[node[1]]
                       handler.from_rep(node[2..-1])
                     elsif node.start_with?(ESC_ESC, ESC_SUB, ESC_RES)
                       node[1..-1]
                     else
                       @default_handler.from_rep(node[1], node[2..-1])
                     end
                   end
          cache.write(parsed) if cache.cacheable?(node, as_map_key)
          parsed
        end
      when Hash
        if node.size == 1
          k = decode(node.keys.first,   cache, true)
          v = decode(node.values.first, cache, false)
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
          node.keys.each do |k|
            node.store(decode(k, cache, true), decode(node.delete(k), cache))
          end
          node
        end
      when Array
        if node[0] == MAP_AS_ARRAY
          decode(Hash[*node.drop(1)], cache, as_map_key)
        else
          node.map! {|n| decode(n, cache, as_map_key)}
        end
      else
        node
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
