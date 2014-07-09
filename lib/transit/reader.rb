# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  # Transit::Reader converts incoming transit data into appropriate values in Ruby.
  # @see https://github.com/cognitect/transit-format
  class Reader

    DEFAULT_READ_HANDLERS = {
      "_" => ReadHandlers::NilHandler.new,
      ":" => ReadHandlers::KeywordHandler.new,
      "?" => ReadHandlers::BooleanHandler.new,
      "b" => ReadHandlers::ByteArrayHandler.new,
      "d" => ReadHandlers::FloatHandler.new,
      "i" => ReadHandlers::IntegerHandler.new,
      "n" => ReadHandlers::BigIntegerHandler.new,
      "f" => ReadHandlers::BigDecimalHandler.new,
      "c" => ReadHandlers::IdentityHandler.new,
      "$" => ReadHandlers::SymbolHandler.new,
      "t" => ReadHandlers::TimeStringHandler.new,
      "m" => ReadHandlers::TimeIntHandler.new,
      "u" => ReadHandlers::UuidHandler.new,
      "r" => ReadHandlers::UriHandler.new,
      "'" => ReadHandlers::IdentityHandler.new,
      "set"     => ReadHandlers::SetHandler.new,
      "link"    => ReadHandlers::LinkHandler.new,
      "list"    => ReadHandlers::IdentityHandler.new,
      "ints"    => ReadHandlers::IdentityHandler.new,
      "longs"   => ReadHandlers::IdentityHandler.new,
      "floats"  => ReadHandlers::IdentityHandler.new,
      "doubles" => ReadHandlers::IdentityHandler.new,
      "bools"   => ReadHandlers::IdentityHandler.new,
      "cmap"    => ReadHandlers::CmapHandler.new
    }.freeze

    DEFAULT_READ_HANDLER = ReadHandlers::Default.new

    # @api private
    class JsonUnmarshaler
      CHUNK_SIZE = 8192

      class ParseHandler
        def each(&block) @yield_v = block end
        def add_value(v) @yield_v[v] if @yield_v end

        def hash_start()      {} end
        def hash_set(h,k,v)   h.store(k,v) end
        def array_start()     [] end
        def array_append(a,v) a << v end

        def error(message, line, column)
          raise Exception.new(message, line, column)
        end
      end

      def initialize(io, opts)
        @io = io
        @decoder = Transit::Decoder.new(opts)
        @parse_handler = ParseHandler.new
      end

      # @see Reader#read
      def read
        if block_given?
          @parse_handler.each {|v| yield @decoder.decode(v)}
        else
          @parse_handler.each {|v| return @decoder.decode(v)}
        end
        Oj.sc_parse(@parse_handler, @io)
      end
    end

    # @api private
    class MessagePackUnmarshaler
      def initialize(io, opts)
        @decoder = Transit::Decoder.new(opts)
        @unpacker = MessagePack::Unpacker.new(io)
      end

      # @see Reader#read
      def read
        if block_given?
          @unpacker.each {|v| yield @decoder.decode(v)}
        else
          @decoder.decode(@unpacker.read)
        end
      end
    end

    extend Forwardable

    # Reads transit values from an IO (file, stream, etc), and
    # converts each one to the appropriate Ruby object.
    #
    # With a block, yields each object to the block as it is processed.
    #
    # Without a block, returns a single object.
    #
    # @example
    #   reader = Transit::Reader.new(:json, io)
    #   reader.read {|obj| do_something_with(obj)}
    #
    #   reader = Transit::Reader.new(:json, io)
    #   obj = reader.read
    def_delegators :@reader, :read

    # @param [Symbol] type, required any of :msgpack, :json, :json_verbose
    # @param [IO]     io, required
    # @param [Hash]   opts, optional
    def initialize(type, io, opts={})
      @reader = case type
                when :json, :json_verbose
                  require 'oj'
                  JsonUnmarshaler.new(io, opts)
                else
                  require 'msgpack'
                  MessagePackUnmarshaler.new(io, opts)
                end
    end
  end
end
