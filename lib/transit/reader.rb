# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class JsonUnmarshaler
    class Handler
      def each(&block)
        @each = block
      end

      def hash_start
        {}
      end

      def hash_set(h,k,v)
        h.store(k,v)
      end

      def array_start
        []
      end

      def array_append(a,v)
        a << v
      end

      def add_value(v)
        @each[v] if @each
      end

      def error(message, line, column)
        raise Exception.new(message, line, column)
      end
    end

    def initialize(io)
      @io = io
      @decoder = Transit::Decoder.new
      @handler = Handler.new
    end

    def register(key, &decoder)
      @decoder.register(key, &decoder)
    end

    def read
      if block_given?
        @handler.each {|v| yield @decoder.decode(v)}
      else
        @handler.each {|v| return @decoder.decode(v)}
      end
      Oj.sc_parse(@handler, @io)
    end
  end

  class MessagePackUnmarshaler
    def initialize(io)
      @decoder = Transit::Decoder.new
      @unpacker = MessagePack::Unpacker.new(io)
    end

    def register(key, &decoder)
      @decoder.register(key, &decoder)
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

    def_delegators :@reader, :read, :register

    def initialize(type, io, opts={})
      @reader = case type
                when :json, :json_verbose
                  require 'oj'
                  JsonUnmarshaler.new(io)
                else
                  require 'msgpack'
                  MessagePackUnmarshaler.new(io)
                end
    end
  end
end
