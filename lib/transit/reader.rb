# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class JsonUnmarshaler
    CHUNK_SIZE = 8192

    def initialize(io, opts)
      @io = io
      @yajl = Yajl::Parser.new
      @decoder = Transit::Decoder.new(opts)
    end

    def read
      if block_given?
        @yajl.on_parse_complete = ->(obj){ yield @decoder.decode(obj) }
        while true
          begin
            @yajl << @io.readpartial(CHUNK_SIZE)
          rescue EOFError => e
            break
          end
        end
      else
        @decoder.decode(@yajl.parse(@io))
      end
    end
  end

  class MessagePackUnmarshaler
    def initialize(io, opts)
      @decoder = Transit::Decoder.new(opts)
      @unpacker = MessagePack::Unpacker.new(io)
    end

    def read
      if block_given?
        @unpacker.each {|v| yield @decoder.decode(v)}
      else
        @decoder.decode(@unpacker.read)
      end
    end
  end

  class Reader
    extend Forwardable

    def_delegators :@reader, :read

    def initialize(type, io, opts={})
      @reader = case type
                when :json, :json_verbose
                  require 'yajl'
                  JsonUnmarshaler.new(io, opts)
                else
                  require 'msgpack'
                  MessagePackUnmarshaler.new(io, opts)
                end
    end
  end
end
