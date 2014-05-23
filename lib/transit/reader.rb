# Copyright (c) Cognitect, Inc.
# All rights reserved.

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

    def read(io)
      if block_given?
        @yajl.on_parse_complete = ->(obj){ yield @decoder.decode(obj) }
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

  class MessagePackUnmarshaler
    def initialize
      @decoder = Transit::Decoder.new
    end

    def register(key, &decoder)
      @decoder.register(key, &decoder)
    end

    def read(io)
      u = MessagePack::Unpacker.new(io)
      if block_given?
        u.each do |o|
          yield @decoder.decode(o)
        end
      else
        @decoder.decode(u.read)
      end
    end
  end

  class Reader
    extend Forwardable

    def_delegators :@reader, :read, :register

    def initialize(type=:json)
      @reader = if type == :json
                  require 'yajl'
                  JsonUnmarshaler.new
                else
                  require 'msgpack'
                  MessagePackUnmarshaler.new
                end
    end
  end
end
