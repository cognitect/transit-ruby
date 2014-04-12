module Transit
  ESC = "~"
  SUB = "^"
  RES = "`"
  TAG = "~#"
end

require 'transit/version'
require 'transit/util'
require 'transit/transit_types'
require 'transit/class_hash'
require 'transit/rolling_cache'
require 'transit/handler'
require 'transit/emitters'
require 'transit/writer'
require 'transit/decoder'
require 'transit/reader'
