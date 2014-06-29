# Copyright (c) Cognitect, Inc.
# All rights reserved.

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

  MAX_INT = 2**63 - 1
  MIN_INT = -MAX_INT

  JSON_MAX_INT = 2**53 - 1
  JSON_MIN_INT = -JSON_MAX_INT
end

require 'transit/version'
require 'transit/date_time_util'
require 'transit/transit_types'
require 'transit/class_hash'
require 'transit/rolling_cache'
require 'transit/handlers'
require 'transit/writer'
require 'transit/decoder'
require 'transit/reader'
