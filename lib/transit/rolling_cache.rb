# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class RollingCache
    extend Forwardable

    def_delegators "@key_to_value", :has_key?, :size

    FIRST_ORD = 33
    CACHE_SIZE = 94**2
    MIN_SIZE_CACHEABLE = 4

    def initialize
      clear
    end

    def read(name, as_map_key=false)
      @key_to_value[name] || maybe_encache(name, as_map_key)
    end

    def write(name, as_map_key=false)
      @value_to_key[name] || maybe_encache(name, as_map_key)
    end

    private

    def cacheable?(str, as_map_key=false)
      str.size >= MIN_SIZE_CACHEABLE && (as_map_key || str.start_with?("~#","~$","~:"))
    end

    def clear
      @key_to_value = {}
      @value_to_key = {}
    end

    def maybe_encache(name, as_map_key)
      cacheable?(name, as_map_key) ? encache(name) : name
    end

    def encache(name)
      clear if @key_to_value.size >= CACHE_SIZE

      @value_to_key[name] || begin
                               key = next_key(@key_to_value.size)
                               @value_to_key[name] = key
                               @key_to_value[key]  = name
                             end
    end

    def next_key(i)
      hi = i / 94;
      lo = i % 94;
      if hi == 0
        "^#{(lo+FIRST_ORD).chr}"
      else
        "^#{(hi+FIRST_ORD).chr}#{(lo+FIRST_ORD).chr}"
      end
    end
  end
end
