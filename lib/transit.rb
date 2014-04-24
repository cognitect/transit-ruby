require 'addressable/uri'

module Transit
  ESC = "~"
  SUB = "^"
  RES = "`"
  TAG = "~#"
  TIME_FORMAT = "%FT%H:%M:%S.%LZ"
end

require 'transit/version'
require 'transit/util'
require 'transit/transit_types'
require 'transit/class_hash'
require 'transit/rolling_cache'
require 'transit/handler'
require 'transit/writer'
require 'transit/decoder'
require 'transit/reader'
