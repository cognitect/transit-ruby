require 'yajl'

module Transit
  class JsonUnmarshaler
    CHUNK_SIZE = 8192

    def initialize(handlers)
      @yajl = Yajl::Parser.new
      @decoder = Transit::Decoder.new(handlers)
    end

    def read(io, &block)
      if block
        @yajl.on_parse_complete = Proc.new do |obj|
          block.call(@decoder.decode(obj, RollingCache.new))
        end
        while true
          begin
          @yajl << io.readpartial(CHUNK_SIZE)
          rescue EOFError => e
            break
          end
        end
      else
        @decoder.decode(@yajl.parse(io), RollingCache.new)
      end
    end
  end

  class Reader
    def initialize(type=:json,handlers=Handler.new)
      @reader = JsonUnmarshaler.new(handlers)
    end

    def read(io, &block)
      @reader.read(io, &block)
    end
  end
end
