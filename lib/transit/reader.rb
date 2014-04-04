require 'yajl'

module Transit
  class JsonUnmarshaler
    def initialize
      @yajl = Yajl::Parser.new
      @decoder = Transit::Decoder.new
    end

    def read(io, &block)
      if block
        @yajl.parse(io) do |obj|
          block.call(@decoder.decode(obj, RollingCache.new))
        end
      else
        @decoder.decode(@yajl.parse(io), RollingCache.new)
      end
    end
  end

  class Reader
    def initialize(type=:json)
      @reader = JsonUnmarshaler.new
    end

    def read(io, &block)
      @reader.read(io, &block)
    end
  end
end
