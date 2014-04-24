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
  assert { actual.year  == expected.year }
  assert { actual.month == expected.month }
  assert { actual.day   == expected.day }
  assert { actual.hour  == expected.hour }
end

def round_trips(label, obj, type, type_to_handle=nil, handler=nil, decoder_key=nil, decoder_fn=nil)
  opts = {}
  it "round trips #{label} at top level", :focus => !!opts[:focus], :pending => opts[:pending] do
    if DateTime === obj
      assert_equal_times(round_trip(obj, type), obj)
    elsif handler && decoder_fn
      assert { round_trip(obj, type, type_to_handle, handler, decoder_key, decoder_fn) == obj }
    else
      assert { round_trip(obj, type) == obj }
    end
  end

  case obj
  when DateTime
    it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
      before = {obj => 0}
      after = round_trip(before, type)
      assert_equal_times(after.keys.first, before.keys.first)
    end
  when Hash, Array, Transit::TransitList, Set, Transit::TypedArray
  else
    it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
      if handler && decoder_fn
        assert { round_trip({obj => 0}, type, type_to_handle, handler, decoder_key, decoder_fn) == {obj => 0} }
      else
        assert { round_trip({obj => 0}, type) == {obj => 0} }
      end
    end
  end

  it "round trips #{label} as a map value", :focus => !!opts[:focus], :pending => opts[:pending] do
    if DateTime === obj
      before = {:a => obj}
      after = round_trip(before, type)
      assert_equal_times(after.values.first, before.values.first)
    elsif handler && decoder_fn
      assert { round_trip({a: obj}, type, type_to_handle, handler, decoder_key, decoder_fn) == {a: obj} }
    else
      assert { round_trip({a: obj}, type) == {a: obj} }
    end
  end

  it "round trips #{label} as an array value", :focus => !!opts[:focus], :pending => opts[:pending] do
    if DateTime === obj
      before = [obj]
      after = round_trip(before, type)
      assert_equal_times(after.first, before.first)
    elsif handler && decoder_fn
      assert { round_trip([obj], type, type_to_handle, handler, decoder_key, decoder_fn) == [obj] }    else
      assert { round_trip([obj], type) == [obj] }
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
    round_trips("an instant (DateTime)", DateTime.now.new_offset(0), type)
    round_trips("a uuid", UUID.new, type)
    round_trips("a uri (url)", URI("http://example.com"), type)
    round_trips("a uri (file)", URI("file:///path/to/file.txt"), type)
    round_trips("a bytearray", ByteArray.new("abcdef\n\r\tghij"), type)
    round_trips("a TransitSymbol", TransitSymbol.new("abc"), type)
    round_trips("a list", TransitList.new([1,2,3]), type)
    round_trips("a hash w/ stringable keys", {"this" => "~hash", "1" => 2}, type)
    round_trips("a set", Set.new([1,2,3]), type)
    round_trips("an array", [1,2,3], type)
    round_trips("an array of ints", IntsArray.new([1,2,3]), type)
    round_trips("an array of longs", LongsArray.new( [1,2,3]), type)
    round_trips("an array of floats", FloatsArray.new([1.1,2.2,3.3]), type)
    round_trips("an array of floats", DoublesArray.new([1.1,2.2,3.3]), type)
    round_trips("an array of floats", BoolsArray.new([true,false,false,true]), type)
    round_trips("an array of maps w/ cacheable keys", [{"this" => "a"},{"this" => "b"}], type)
    round_trips("a char", Char.new("x"), type)
    round_trips("an extension scalar", PhoneNumber.new("555","867","5309"), type,
                PhoneNumber, PhoneNumberHandler,
                "P", ->(p){PhoneNumber.parse(p)})
    round_trips("an extension struct", Person.new("First","Last",:today), type,
                Person, PersonHandler,
                "person", ->(p){Person.new(p[:first_name],p[:last_name],p[:birthdate])})
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
