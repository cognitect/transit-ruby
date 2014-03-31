require 'oj'

module Transit
  class Handler
    extend Forwardable

    def_delegators :@handlers, :[]=

    def initialize
      @handlers = ClassHash.new
      @handlers[String] = StringHandler.new
      @handlers[Time] = InstantHandler.new
      @handlers[Fixnum] = IntHandler.new
      @handlers[Float] = FloatHandler.new
      @handlers[Array] = ArrayHandler.new
      @handlers[Hash] = MapHandler.new
      @handlers[Symbol] = SymbolHandler.new
      @handlers[TransitSymbol] = SymbolHandler.new
      @handlers[NilClass] = NilHandler.new
      @handlers[TrueClass] = TrueHandler.new
      @handlers[FalseClass] = FalseHandler.new
      @handlers[URI] = UriHandler.new
      @handlers[BigDecimal] = BigDecimalHandler.new
      @handlers[ByteArray] = ByteArrayHandler.new
    end

    # Bignum
    # ByteArray

    def [](obj)
      @handlers[obj.class]
    end

    class NilHandler
      def tag(_) "_" end
      def rep(_) nil end
      def string_rep(n) nil end
    end

    class FalseHandler
      def tag(_) "?" end
      def rep(_) false end
      def string_rep(_) "f" end
    end

    class TrueHandler
      def tag(_) "?" end
      def rep(_) true end
      def string_rep(_) "t" end
    end

    class StringHandler
      def tag(s) "s" end
      def rep(s) s end
      def string_rep(s) s end
    end

    class InstantHandler
      def tag(t) "t" end
      def rep(t) t.strftime("%FT%H:%M:%S.%LZ") end
      def string_rep(t) rep(t) end
    end

    class IntHandler
      def tag(i) "i" end
      def rep(i) i end
      def string_rep(i) i.to_s end
    end

    class FloatHandler
      def tag(f) "d" end
      def rep(f) f end
      def string_rep(f) f.to_s end
    end

    class BigDecimalHandler
      def tag(f) "f" end
      def rep(f) f.to_s("f") end
      def string_rep(f) rep(f) end
    end

    class ArrayHandler
      def tag(a) :array end
      def rep(a) a end
      def string_rep(_) nil end
    end

    class MapHandler
      def tag(m) :map end
      def rep(m) m end
      def string_rep(_) nil end
    end

    class SymbolHandler
      def tag(s) ":" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class UriHandler
      def tag(u) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class ByteArrayHandler
      def tag(b) "b" end
      def rep(b) b.to_base64 end
      def string_rep(b) rep(b) end
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
      return s if [nil, true, false].include? s
      (s && [ESC, SUB, RESERVED].include?(s[0])) ? "#{ESC}#{s}" : s
    end

    def encode_string(obj, as_map_key)
      handler = @handlers[obj]
      if tag = handler.tag(obj)
        str_rep = escape(handler.string_rep(obj))
        String === obj ? str_rep : "#{ESC}#{tag}#{str_rep}"
      end
    end

    def emit_nil(_, _cache_)
      @oj.push_value(nil)
    end

    def emit_boolean(b, _cache_)
      @oj.push_value(b)
    end

    def emit_string(prefix, tag, string, _cache_)
      @oj.push_value("#{prefix}#{tag}#{escape(string)}")
    end

    def emit_number(i, _cache_)
      @oj.push_value(i)
    end

    def emit_array(a, _cache_)
      @oj.push_array
      a.each {|e| marshal(e, _cache_)}
      @oj.pop
    end

    def emit_map(a, _cache_)
      @oj.push_object
      a.each do |k,v|
        @oj.push_key(encode_string(k, true))
        marshal(v, _cache_)
      end
      @oj.pop
    end

    def emit_encoded(tag, obj, _cache_)
      if tag
        handler = @handlers[obj]
        if String === rep = handler.rep(obj)
          emit_string(ESC, tag, rep, _cache_)
        end
      end
    end

    def marshal(obj, _cache_)
      handler = @handlers[obj]
      tag = handler.tag(obj)
      rep = handler.rep(obj)
      case tag
      when "s"
        emit_string(nil, nil, rep, _cache_)
      when "i", "d"
        emit_number(rep, _cache_)
      when "_"
        emit_nil(rep, _cache_)
      when "?"
        emit_boolean(rep, _cache_)
      when :array
        emit_array(rep, _cache_)
      when :map
        emit_map(rep, _cache_)
      else
        emit_encoded(tag, obj, _cache_)
      end
    end
  end

  class Writer
    def initialize(io, type)
      @marshaler = JsonMarshaler.new(io)
    end

    def write(obj)
      @marshaler.marshal(obj, nil)
    end
  end
end
