require 'set'

module Transit
  class Handler
    extend Forwardable

    def_delegators :@handlers, :[]=

    def initialize
      @handlers = ClassHash.new
      @handlers[NilClass]      = NilHandler.new
      @handlers[Symbol]        = KeywordHandler.new
      @handlers[String]        = StringHandler.new
      @handlers[TrueClass]     = TrueHandler.new
      @handlers[FalseClass]    = FalseHandler.new
      @handlers[Fixnum]        = IntHandler.new
      @handlers[Bignum]        = BignumHandler.new
      @handlers[Float]         = FloatHandler.new
      @handlers[BigDecimal]    = BigDecimalHandler.new
      @handlers[Time]          = InstantHandler.new
      @handlers[UUID]          = UuidHandler.new
      @handlers[URI]           = UriHandler.new
      @handlers[ByteArray]     = ByteArrayHandler.new
      @handlers[TransitSymbol] = TransitSymbolHandler.new
      @handlers[Array]         = ArrayHandler.new
      @handlers[TransitList]   = ListHandler.new
      @handlers[Hash]          = MapHandler.new
      @handlers[Set]           = SetHandler.new
      @handlers[IntsArray]     = IntsArrayHandler.new
      @handlers[LongsArray]    = LongsArrayHandler.new
      @handlers[DoublesArray]  = DoublesArrayHandler.new
      @handlers[FloatsArray]   = FloatsArrayHandler.new
      @handlers[BoolsArray]    = BoolsArrayHandler.new
      @handlers[Char]          = CharHandler.new
      @handlers[CMap]          = CMapHandler.new
      @handlers[Quote]         = QuoteHandler.new
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
      def tag() "_" end
      def rep(_) nil end
      def string_rep(n) nil end
    end

    class KeywordHandler
      def tag() ":" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class StringHandler
      def tag() "s" end
      def rep(s) s end
      def string_rep(s) s end
    end

    class TrueHandler
      def tag() "?" end
      def rep(_) true end
      def string_rep(_) "t" end
    end

    class FalseHandler
      def tag() "?" end
      def rep(_) false end
      def string_rep(_) "f" end
    end

    class IntHandler
      def tag() "i" end
      def rep(i) i end
      def string_rep(i) i.to_s end
    end

    class BignumHandler < IntHandler; end

    class FloatHandler
      def tag() "d" end
      def rep(f) f end
      def string_rep(f) f.to_s end
    end

    class BigDecimalHandler
      def tag() "f" end
      def rep(f) f.to_s("f") end
      def string_rep(f) rep(f) end
    end

    class InstantHandler
      def tag() "t" end
      def rep(t) t.strftime("%FT%H:%M:%S.%LZ") end
      def string_rep(t) rep(t) end
    end

    class UuidHandler
      def tag() "u" end
      def rep(u) string_rep(u) end
      def string_rep(u) u.to_s end
    end

    class UriHandler
      def tag() "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class ByteArrayHandler
      def tag() "b" end
      def rep(b) b.to_base64 end
      def string_rep(b) rep(b) end
    end

    class TransitSymbolHandler
      def tag() "$" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class ArrayHandler
      def tag() :array end
      def rep(a) a end
      def string_rep(_) nil end
    end

    class MapHandler
      def tag() :map end
      def rep(m) m end
      def string_rep(_) nil end
    end

    class SetHandler
      def tag() "set" end
      def rep(s) TaggedMap.new(:array, s.to_a, nil) end
      def string_rep(_) nil end
    end

    class ListHandler
      def tag() "list" end
      def rep(l) TaggedMap.new(:array, l.to_a, nil) end
      def string_rep(_) nil end
    end

    module TypedArrayHandler
      def initialize(type)
        @type = type
      end
      def tag() @type end
      def rep(a) TaggedMap.new(:array, a.to_a, nil) end
      def string_rep(_) nil end
    end

    class IntsArrayHandler
      include TypedArrayHandler
      def initialize
        super("ints")
      end
    end

    class LongsArrayHandler
      include TypedArrayHandler
      def initialize
        super("longs")
      end
    end

    class FloatsArrayHandler
      include TypedArrayHandler
      def initialize
        super("floats")
      end
    end

    class DoublesArrayHandler
      include TypedArrayHandler
      def initialize
        super("doubles")
      end
    end

    class BoolsArrayHandler
      include TypedArrayHandler
      def initialize
        super("bools")
      end
    end

    class CharHandler
      def tag() "c" end
      def rep(c) string_rep(c) end
      def string_rep(c) c.to_s end
    end

    class CMapHandler
      def tag() "cmap" end
      def rep(cm) TaggedMap.new(:array, cm.to_a, nil) end
      def string_rep(_) nil end
    end

    class QuoteHandler
      def tag() "'" end
      def rep(q) q.value end
      def string_rep(s) nil end
    end
  end
end
