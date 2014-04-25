module Transit
  class JsonUnmarshaler
    CHUNK_SIZE = 8192

    def initialize
      @yajl = Yajl::Parser.new
      @decoder = Transit::Decoder.new
    end

    def register(key, &decoder)
      @decoder.register(key, &decoder)
    end

    def read(io, &block)
      if block
        @yajl.on_parse_complete = Proc.new do |obj|
          block.call(@decoder.decode(obj))
        end
        while true
          begin
          @yajl << io.readpartial(CHUNK_SIZE)
          rescue EOFError => e
            break
          end
        end
      else
        @decoder.decode(@yajl.parse(io))
      end
    end
  end

  class MsgpackUnmarshaler
    def initialize
      @decoder = Transit::Decoder.new
    end

    def register(key, &decoder)
      @decoder.register(key, &decoder)
    end

    def read(io, &block)
      u = MessagePack::Unpacker.new(io)
      if block
        u.each do |o|
          block.call(@decoder.decode(o))
        end
      else
        @decoder.decode(u.read)
      end
    end
  end

  class Reader
    def initialize(type=:json)
      @reader = if type == :json
                  require 'yajl'
                  JsonUnmarshaler.new
                else
                  require 'msgpack'
                  MsgpackUnmarshaler.new
                end
    end

    def read(io, &block)
      @reader.read(io, &block)
    end

    def register(key, &decoder)
      @reader.register(key, &decoder)
    end
  end
end
