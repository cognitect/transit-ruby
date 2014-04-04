module Transit
  class RollingCache
    FIRST_ORD = 33
    CACHE_SIZE = 94
    MIN_SIZE_CACHEABLE = 4

    def initialize
      clear
    end

    # Always returns the name
    def decode(name, as_map_key=false)
      return @key_to_value[name] if cache_key?(name)
      return name unless cacheable?(name, as_map_key)
      encache(name)
    end

    # Returns the name the first time and the key after that
    def encode(name, as_map_key=false)
      key = @value_to_key[name]
      return key if key
      return encache(name) if cacheable?(name, as_map_key)
      name
    end

    def cache_key?(name)
      name[0] == '^'
    end

    def clear
      @key_to_value = {}
      @value_to_key = {}
    end

    def size
      @key_to_value.size
    end

    def cache_full?
      @key_to_value.size >= CACHE_SIZE
    end

    ESCAPED = /^~(#|\$|:)/

    def cacheable?(str, as_map_key=false)
      str && str.size >= MIN_SIZE_CACHEABLE && (as_map_key || ESCAPED =~ str)
    end

    private

    def encache(name)
      clear if cache_full?

      existing_key = @value_to_key[name]
      return existing_key if existing_key

      encode_key(@key_to_value.size).tap do |key|
        @key_to_value[key] = name
        @value_to_key[name] = key
      end
      name
    end

    def encode_key(i)
      "^#{(i+FIRST_ORD).chr}"
    end

    def decode_key(s)
      s[1].ord - FIRST_ORD
    end
  end
end
