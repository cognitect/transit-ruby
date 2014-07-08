# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  # @api private
  class RollingCache
    extend Forwardable

    def_delegators "@key_to_value", :has_key?, :size

    FIRST_ORD = 33
    CACHE_SIZE = 94**2
    MIN_SIZE_CACHEABLE = 4

    def initialize
      clear
    end

    def read(key)
      @key_to_value[key]
    end

    def write(val)
      @value_to_key[val] || begin
                              clear if @key_to_value.size >= CACHE_SIZE
                              key = next_key(@key_to_value.size)
                              @value_to_key[val] = key
                              @key_to_value[key] = val
                            end
    end

    def cache_key?(str, _=false)
      str[0] == SUB && str != MAP_AS_ARRAY
    end

    def cacheable?(str, as_map_key=false)
      str.size >= MIN_SIZE_CACHEABLE && (as_map_key || str.start_with?("~#","~$","~:"))
    end

    private

    def clear
      @key_to_value = {}
      @value_to_key = {}
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
