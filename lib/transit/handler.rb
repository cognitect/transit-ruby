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
      @handlers[Time]          = TimeHandler.new
      @handlers[DateTime]      = DateTimeHandler.new
      @handlers[Date]          = DateHandler.new
      @handlers[UUID]          = UuidHandler.new
      @handlers[URI]           = UriHandler.new
      @handlers[Addressable::URI] = AddressableUriHandler.new
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
      @handlers[Quote]         = QuoteHandler.new
      @handlers[TaggedMap]     = TaggedMapHandler.new
      @handlers[TaggedValue]   = TaggedValueHandler.new
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

    class KeywordHandler
      def tag(_) ":" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class StringHandler
      def tag(_) "s" end
      def rep(s) s end
      def string_rep(s) s end
    end

    class TrueHandler
      def tag(_) "?" end
      def rep(_) true end
      def string_rep(_) "t" end
    end

    class FalseHandler
      def tag(_) "?" end
      def rep(_) false end
      def string_rep(_) "f" end
    end

    class IntHandler
      def tag(_) "i" end
      def rep(i) i end
      def string_rep(i) i.to_s end
    end

    class BignumHandler < IntHandler; end

    class FloatHandler
      def tag(_) "d" end
      def rep(f) f end
      def string_rep(f) f.to_s end
    end

    class BigDecimalHandler
      def tag(_) "f" end
      def rep(f) f.to_s("f") end
      def string_rep(f) rep(f) end
    end

    # TimeHandler, DateTimeHandler, and DateHandler all have different
    # implementations of string_rep. Here is the rationale:
    #
    # For all three, want to write out the same format
    # e.g. 2014-04-18T18:51:29.478Z, and we want the milliseconds to truncate
    # rather than round, eg 29.4786 seconds should be 29.478, not 29.479.
    # - "sss is the number of complete milliseconds since the start of the
    #    second as three decimal digits."
    # - http://www.ecma-international.org/ecma-262/5.1/#sec-15.9.1.15
    #
    # Some data points (see benchmarks/encoding_time.rb)
    # - Time and DateTime each offer iso8601 methods, but strftime is faster.
    # - DateTime's strftime (and iso8601) round millis
    # - Time's strftime (and iso8601) truncate millis
    # - we don't care about truncate v round for dates (which have 000 ms)
    # - date.to_datetime.strftime(...) is considerably faster than date.to_time.strftime(...)
    class TimeHandler
      def tag(_) "t" end
      def rep(t) DateTimeUtil.to_millis(t) end
      def string_rep(t)
        # .getutc because we don't want to modify t
        t.getutc.strftime(Transit::TIME_FORMAT)
      end
    end

    class DateTimeHandler
      def tag(_) "t" end
      def rep(t) DateTimeUtil.to_millis(t) end
      def string_rep(t)
        # .utc because to_time already creates a new object
        t.to_time.utc.strftime(Transit::TIME_FORMAT)
      end
    end

    class DateHandler
      def tag(_) "t" end
      def rep(d) DateTimeUtil.to_millis(d) end
      def string_rep(d)
        # to_datetime because DateTime's strftime is faster
        # thank Time's, and millis are 000 so it doesn't matter
        # if we truncate or round.
        d.to_datetime.strftime(Transit::TIME_FORMAT)
      end
    end

    class UuidHandler
      def tag(_) "u" end
      def rep(u) [u.most_significant_bits, u.least_significant_bits] end
      def string_rep(u) u.to_s end
    end

    class UriHandler
      def tag(_) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class AddressableUriHandler
      def tag(_) "r" end
      def rep(u) u.to_s end
      def string_rep(u) rep(u) end
    end

    class ByteArrayHandler
      def tag(_) "b" end
      def rep(b) b.to_base64 end
      def string_rep(b) rep(b) end
    end

    class TransitSymbolHandler
      def tag(_) "$" end
      def rep(s) s.to_s end
      def string_rep(s) rep(s) end
    end

    class ArrayHandler
      def tag(_) :array end
      def rep(a) a end
      def string_rep(_) nil end
    end

    class MapHandler
      def tag(m) :map end
      def rep(m) m end
      def string_rep(_) nil end
    end

    class SetHandler
      def tag(_) "set" end
      def rep(s) TaggedMap.new(:array, s.to_a, nil) end
      def string_rep(_) nil end
    end

    class ListHandler
      def tag(_) "list" end
      def rep(l) TaggedMap.new(:array, l.to_a, nil) end
      def string_rep(_) nil end
    end

    module TypedArrayHandler
      def initialize(type)
        @type = type
      end
      def tag(_) @type end
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
      def tag(_) "c" end
      def rep(c) string_rep(c) end
      def string_rep(c) c.to_s end
    end

    class QuoteHandler
      def tag(_) "'" end
      def rep(q) q.value end
      def string_rep(s) nil end
    end

    class TaggedMapHandler
      def tag(tm) tm.tag end
      def rep(tm) tm.rep end
      def string_rep(tm) tm.to_s end
    end

    class TaggedValueHandler
      def tag(tv) :tagged_value end
      def rep(tv) {tv.tag => tv.value} end
      def string_rep(_) nil end
    end
  end
end
