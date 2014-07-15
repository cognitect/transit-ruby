# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Transit
  # @api private
  class RollingCache
    extend Forwardable

    def_delegators "@key_to_value", :has_key?, :size

    FIRST_ORD = 48
    LAST_ORD  = 91
    CACHE_CODE_DIGITS = 44;
    CACHE_SIZE = CACHE_CODE_DIGITS * CACHE_CODE_DIGITS;
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
      hi = i / CACHE_CODE_DIGITS;
      lo = i % CACHE_CODE_DIGITS;
      if hi == 0
        "^#{(lo+FIRST_ORD).chr}"
      else
        "^#{(hi+FIRST_ORD).chr}#{(lo+FIRST_ORD).chr}"
      end
    end
  end
end
