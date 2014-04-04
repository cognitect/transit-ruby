require 'set'

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
      @handlers[Symbol] = KeywordHandler.new
      @handlers[TransitSymbol] = TransitSymbolHandler.new
      @handlers[NilClass] = NilHandler.new
      @handlers[TrueClass] = TrueHandler.new
      @handlers[FalseClass] = FalseHandler.new
      @handlers[URI] = UriHandler.new
      @handlers[BigDecimal] = BigDecimalHandler.new
      @handlers[ByteArray] = ByteArrayHandler.new
      @handlers[Set] = SetHandler.new
      @handlers[TransitList] = ListHandler.new
      @handlers[TypedArray] = TypedArrayHandler.new
      @handlers[UUID] = UuidHandler.new
      @handlers[Char] = CharHandler.new
      @handlers[CMap] = CMapHandler.new
      @handlers[Quote] = QuoteHandler.new
    end

    def [](obj)
      @handlers[obj.class]
    end

    class TaggedMap
      attr_reader :tag, :rep, :string_rep
      def initialize(tag, rep, str)
        @tag = tag
        @rep = rep
        @string_rep = str
      end
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

    class SetHandler
      def tag(s) "set" end
      def rep(s) TaggedMap.new(:array, s.to_a, nil) end
      def string_rep(_) nil end
    end

    class ListHandler
      def tag(l) "list" end
      def rep(l) TaggedMap.new(:array, l.to_a, nil) end
      def string_rep(_) nil end
    end

    class MapHandler
      def tag(m) :map end
      def rep(m) m end
      def string_rep(_) nil end
    end

    class KeywordHandler
      def tag(s) ":" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class TransitSymbolHandler
      def tag(s) "$" end
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

    class TypedArrayHandler
      def tag(a) a.type end
      def rep(a) TaggedMap.new(:array, a.to_a, nil) end
      def string_rep(_) nil end
    end

    class UuidHandler
      def tag(_) "u" end
      def rep(u) string_rep(u) end
      def string_rep(u) u.to_s end
    end

    class CharHandler
      def tag(_) "c" end
      def rep(c) string_rep(c) end
      def string_rep(c) c.to_s end
    end

    class CMapHandler
      def tag(_) "cmap" end
      def rep(cm) TaggedMap.new(:array, cm.to_a, nil) end
      def string_rep(_) nil end
    end

    class QuoteHandler
      def tag(_) "'" end
      def rep(q) q.value end
      def string_rep(s) nil end
    end
  end
end
