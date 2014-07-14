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

require 'set'
require 'time'
require 'uri'
require 'base64'
require 'bigdecimal'
require 'securerandom'
require 'forwardable'
require 'addressable/uri'

module Transit
  ESC = "~"
  SUB = "^"
  RES = "`"
  TAG = "~#"
  MAP_AS_ARRAY = "^ "
  TIME_FORMAT  = "%FT%H:%M:%S.%LZ"
  QUOTE = "'"

  MAX_INT = 2**63 - 1
  MIN_INT = -2**63

  JSON_MAX_INT = 2**53 - 1
  JSON_MIN_INT = -JSON_MAX_INT
end

require 'transit/date_time_util'
require 'transit/transit_types'
require 'transit/rolling_cache'
require 'transit/write_handlers'
require 'transit/read_handlers'
require 'transit/writer'
require 'transit/decoder'
require 'transit/reader'
