require 'spec_helper'

def round_trip(obj, type, type_to_handle=nil, handler=nil, decoder_key=nil, decoder_fn=nil)
  io = StringIO.new('', 'w+')
  writer = Transit::Writer.new(io, type)
  writer.register(type_to_handle, handler) if handler
  writer.write(obj)
  reader = Transit::Reader.new(type)
  reader.register(decoder_key, &decoder_fn) if decoder_key && decoder_fn
  reader.read(StringIO.new(io.string))
end

def assert_equal_times(actual,expected)
  assert { actual.zone == expected.zone }
  assert { Transit::DateTimeUtil.to_millis(actual) == Transit::DateTimeUtil.to_millis(expected) }
end

def round_trips(label, obj, type, opts={})
  expected = opts[:expected] || obj

  it "round trips #{label} at top level", :focus => !!opts[:focus], :pending => opts[:pending] do
    case obj
    when Date, Time, DateTime
      assert_equal_times(round_trip(obj, type), expected)
    else
      actual = round_trip(obj, type, opts[:type_to_handle], opts[:handler], opts[:decoder_key], opts[:decoder_fn])
      assert { actual == expected }
    end
  end

  case obj
  when Date, Time, DateTime
    it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
      after = round_trip({obj => 0}, type)
      assert_equal_times(after.keys.first, expected)
    end
  when Hash, Array, Transit::TransitList, Set, Transit::TypedArray
  else
    it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
      actual = round_trip({obj => 0}, type, opts[:type_to_handle], opts[:handler], opts[:decoder_key], opts[:decoder_fn])
      assert { actual == {expected => 0} }
    end
  end

  it "round trips #{label} as a map value", :focus => !!opts[:focus], :pending => opts[:pending] do
    case obj
    when Date, Time, DateTime
      after = round_trip({:a => obj}, type)
      assert_equal_times(after.values.first, expected)
    else
      actual = round_trip({a: obj}, type, opts[:type_to_handle], opts[:handler], opts[:decoder_key], opts[:decoder_fn])
      assert { actual == {a: expected} }
    end
  end

  it "round trips #{label} as an array value", :focus => !!opts[:focus], :pending => opts[:pending] do
    case obj
    when Date, Time, DateTime
      after = round_trip([obj], type)
      assert_equal_times(after.first, expected)
    else
      actual = round_trip([obj], type, opts[:type_to_handle], opts[:handler], opts[:decoder_key], opts[:decoder_fn])
      assert { actual == [expected] }
    end
  end
end

module Transit
  PhoneNumber = Struct.new(:area, :prefix, :suffix)
  def PhoneNumber.parse(p)
    area, prefix, suffix = p.split(".")
    PhoneNumber.new(area, prefix, suffix)
  end

  class PhoneNumberHandler
    def tag(_) "P" end
    def rep(p) "#{p.area}.#{p.prefix}.#{p.suffix}" end
    def string_rep(p) rep(p) end
  end

  shared_examples "round trips" do |type|
    round_trips("nil", nil, type)
    round_trips("a keyword", :foo, type)
    round_trips("a string", "this string", type)
    round_trips("a string starting with ~", "~this string", type)
    round_trips("a string starting with ^", "^!", type)
    round_trips("a string starting with `", "`%", type)
    round_trips("true", true, type)
    round_trips("false", false, type)
    round_trips("a small int", 1, type)
    round_trips("a big int", 123456789012345, type)
    round_trips("a very big int", 123456789012345679012345678890, type)
    round_trips("a float", 1234.56, type)
    round_trips("a bigdec", BigDecimal.new("123.45"), type)
    round_trips("an instant (DateTime local)", DateTime.new(2014,1,2,3,4,5.6789, "-5"), type,
                :expected => DateTime.new(2014,1,2, (3+5) ,4,5.6789))
    round_trips("an instant (DateTime gmt)", DateTime.new(2014,1,2,3,4,5.6789), type)
    round_trips("an instant (Time local)", Time.new(2014,1,2,3,4,5.6789, "-05:00"), type,
                :expected => DateTime.new(2014,1,2, (3+5) ,4,5.6789, "+0"))
    round_trips("an instant (Time gmt)", Time.new(2014,1,2,3,4,5.6789, "+00:00"), type,
                :expected => DateTime.new(2014,1,2,3,4,5.6789))
    round_trips("a Date", Date.new(2014,1,2), type, :expected => DateTime.new(2014,1,2))
    round_trips("a uuid", UUID.new, type)
    round_trips("a uri (url)", Addressable::URI.parse("http://example.com"), type)
    round_trips("a uri (file)", Addressable::URI.parse("file:///path/to/file.txt"), type)
    round_trips("a bytearray", ByteArray.new("abcdef\n\r\tghij"), type)
    round_trips("a TransitSymbol", TransitSymbol.new("abc"), type)
    round_trips("a list", TransitList.new([1,2,3]), type, :expected => [1,2,3])
    round_trips("a hash w/ stringable keys", {"this" => "~hash", "1" => 2}, type)
    round_trips("a set", Set.new([1,2,3]), type)
    round_trips("an array", [1,2,3], type)
    round_trips("an array of ints", IntsArray.new([1,2,3]), type, :expected => [1,2,3])
    round_trips("an array of longs", LongsArray.new( [1,2,3]), type, :expected => [1,2,3])
    round_trips("an array of floats", FloatsArray.new([1.1,2.2,3.3]), type, :expected => [1.1,2.2,3.3])
    round_trips("an array of doubles", DoublesArray.new([1.1,2.2,3.3]), type, :expected => [1.1,2.2,3.3])
    round_trips("an array of bools", BoolsArray.new([true,false,false,true]), type, :expected => [true,false,false,true])
    round_trips("an array of maps w/ cacheable keys", [{"this" => "a"},{"this" => "b"}], type)
    round_trips("a char", Char.new("x"), type, :expected => "x")
    round_trips("an extension scalar", PhoneNumber.new("555","867","5309"), type,
                :type_to_handle => PhoneNumber,
                :handler => PhoneNumberHandler,
                :decoder_key => "P",
                :decoder_fn => ->(p){PhoneNumber.parse(p)})
    round_trips("an extension struct", Person.new("First","Last",:today), type,
                :type_to_handle => Person,
                :handler => PersonHandler,
                :decoder_key => "person",
                :decoder_fn => ->(p){Person.new(p[:first_name],p[:last_name],p[:birthdate])})
    round_trips("a hash with simple values", {'a' => 1, 'b' => 2, 'name' => 'russ'}, type)
    round_trips("a hash with TransitSymbols", {TransitSymbol.new("foo") => TransitSymbol.new("bar")}, type)
    round_trips("a hash with 53 bit ints",  {2**53-1 => 2**53-2}, type)
    round_trips("a hash with 54 bit ints",  {2**53   => 2**53+1}, type)
    round_trips("a map with composite keys", {{a: :b} => {c: :d}}, type)
  end

  describe "Transit using json" do
    include_examples "round trips", :json
  end

  describe "Transit using msgpack" do
    include_examples "round trips", :msgpack
  end
end
