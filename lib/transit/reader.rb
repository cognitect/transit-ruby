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

    # Reads a single value from an input source in Json format
    #
    # @return the value
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

    # Reads a single value from an input source in MessagePack format
    #
    # @return the value
    def read
      if block_given?
        @unpacker.each {|v| yield @decoder.decode(v)}
      else
        @decoder.decode(@unpacker.read)
      end
    end
  end

  # Transit::Reader converts incoming transit data into appropriate values in Ruby.
  # @example
  #   > echo "[1,2,3]" | ruby -r transit -e "p Transit::Reader.new(:json, STDIN).read"
  #   # => [1, 2, 3]
  #
  # @see https://github.com/cognitect/transit-format
  class Reader
    extend Forwardable

    # @!method read
    #   @see JsonUnmarshaler#read
    #   @see MessagePackUnmarshaler#read
    def_delegators :@reader, :read

    # @param [Symbol] type required, any of :msgpack, :json, :json_verbose
    # @param [IO]     io required
    # @param [Hash]   opts
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
