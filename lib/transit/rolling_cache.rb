# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class RollingCache
    FIRST_ORD = 33
    CACHE_SIZE = 94
    MIN_SIZE_CACHEABLE = 4

    def initialize
      clear
    end

    def clear
      @key_to_value = {}
      @value_to_key = {}
    end

    def maybe_encache(name, as_map_key)
      cacheable?(name, as_map_key) ? encache(name) : name
    end

    def decode(name, as_map_key=false)
      if val = @key_to_value[name]
        val
      else
        maybe_encache(name, as_map_key)
      end
    end

    def encode(name, as_map_key=false)
      if key = @value_to_key[name]
        key
      else
        maybe_encache(name, as_map_key)
      end
    end

    def cache_key?(name)
      @key_to_value.has_key?(name)
    end

    def size
      @key_to_value.size
    end

    def cache_full?
      @key_to_value.size >= CACHE_SIZE
    end

    ESCAPED = /^~(#|\$|:)/

    def cacheable?(str, as_map_key=false)
      str.size >= MIN_SIZE_CACHEABLE && (as_map_key || ESCAPED =~ str)
    end

    private

    def encache(name)
      clear if cache_full?

      if existing_key = @value_to_key[name]
        existing_key
      else
        encode_key(@key_to_value.size).tap do |key|
          @key_to_value[key]  = name
          @value_to_key[name] = key
        end
        name
      end
    end

    def encode_key(i)
      "^#{(i+FIRST_ORD).chr}"
    end

    def decode_key(s)
      s[1].ord - FIRST_ORD
    end
  end
end
