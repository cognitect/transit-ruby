require 'spec_helper'

module Transit
  class Handler
    extend Forwardable

    def_delegators :@handlers, :[]=

    def initialize
      @handlers = ClassHash.new
      @handlers[String] = StringHandler.new
      @handlers[Time] = InstantHandler.new
      @handlers[Fixnum] = IntHandler.new
      @handlers[Array] = ArrayHandler.new
      @handlers[Hash] = MapHandler.new
    end

    def [](obj)
      @handlers[obj.class]
    end

    class StringHandler
      def tag(s) "s" end
      def rep(s) s end
      def string_rep(s) s end
    end

    class InstantHandler
      def tag(t) "t" end
      def rep(t) t.strftime("%FT%H:%M:%S.%LZ") end
      def string_rep(t) nil end
    end

    class IntHandler
      def tag(i) "i" end
      def rep(i) i end
      def string_rep(i) i.to_s end
    end

    class ArrayHandler
      def tag(a) :array end
      def rep(a) a end
      def string_rep(a) nil end
    end

    class MapHandler
      def tag(m) :map end
      def rep(m) m end
      def string_rep(m) nil end
    end
  end

  class Oj::StreamWriter
    alias orig_push_value  push_value

    def push_value(v, k=nil)
      if @pushing_map_entry
        if @map_key
          @map_value = v
        else
          @map_key = v
        end
      else
        if k
          orig_push_value(v, k)
        else
          orig_push_value(v)
        end
      end
    end

    def push_map_entry
      @pushing_map_entry = true
    end

    def flush_map_entry
      orig_push_value(@map_value, @map_key)
      @pushing_map_entry = @map_value = @map_key = nil
    end
  end

  class JsonMarshaler
    ESC = "~"
    SUB = "^"
    RESERVED = "`"

    def initialize(io)
      @oj = Oj::StreamWriter.new(io)
      @handlers = Handler.new
    end

    def escape(s)
      [ESC, SUB, RESERVED].include?(s[0]) ? "#{ESC}#{s}" : s
    end

    def emit_string(prefix, tag, string, _as_map_key_, _cache_)
      @oj.push_value("#{prefix}#{tag}#{string}")
    end

    def emit_int(i, _as_map_key_, _cache_)
      @oj.push_value(i)
    end

    def emit_array(a, _as_map_key_, _cache_)
      @oj.push_array
      a.each {|e| marshal(e, _as_map_key_, _cache_)}
      @oj.pop
    end

    def emit_map(obj, _as_map_key_, _cache_)
      @oj.push_object
      obj.each do |k, v|
        @oj.push_map_entry
        marshal(k, true, _cache_)
        marshal(v, false, _cache_)
        @oj.flush_map_entry
      end
      @oj.pop
    end

    def marshal(obj, _as_map_key_, _cache_)
      handler = @handlers[obj]
      tag = handler.tag(obj)
      rep = handler.rep(obj)
      case tag
      when "s"
        emit_string(nil, nil, escape(rep), _as_map_key_, _cache_)
      when "i"
        emit_int(rep, _as_map_key_, _cache_)
      when :array
        emit_array(rep, _as_map_key_, _cache_)
      when :map
        emit_map(rep, _as_map_key_, _cache_)
      else
        emit_encoded(tag, obj, _as_map_key_, _cache_)
      end
    end

    def emit_encoded(tag, obj, _as_map_key_, _cache_)
      if tag
        handler = @handlers[obj]
        rep = handler.rep(obj)
        if String === rep
          emit_string(ESC, tag, rep, _as_map_key_, _cache_)
        end
      end
    end
  end

  class Writer
    def initialize(io, type)
      @marshaler = JsonMarshaler.new(io)
    end

    def write(obj)
      @marshaler.marshal(obj, false, nil)
    end
  end
end

module Transit
  describe Writer do
    describe :json, :focus do
      let(:io) { StringIO.new }
      let(:writer) { Writer.new(io, :json) }

      it "marshals a string" do
        writer.write("this")
        assert { io.string == "\"this\"" }
      end

      it "escapes a string that begins with ~" do
        writer.write("~this")
        assert { io.string == "\"~~this\"" }
      end

      it "marshals an instant" do
        t = Time.now
        writer.write(t)
        assert { io.string == "\"~t#{t.strftime("%FT%H:%M:%S.%LZ")}\"" }
      end

      it "marshals an int" do
        writer.write(37)
        assert { io.string == "37" }
      end

      it "marshals an array" do
        writer.write([1])
        assert { io.string == "[1]" }
      end

      it "marshals an array with several elements including nested arrays" do
        writer.write([1, "2", [3, ["~4"]]])
        assert { io.string == "[1,\"2\",[3,[\"~~4\"]]]" }
      end

      it "marshals a map w/ string keys" do
        writer.write({"a" => 1, "b" => "c"})
        assert { io.string == "{\"a\":1,\"b\":\"c\"}" }
      end

      it "marshals a map w/ string keys that require escaping" do
        writer.write({"~a" => 1, "b" => "c"})
        assert { io.string == "{\"~~a\":1,\"b\":\"c\"}" }
      end
    end
  end
end

