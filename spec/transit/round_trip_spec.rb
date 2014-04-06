require 'spec_helper'

def round_trip(obj, type)
  io = StringIO.new('', 'w+')
  Transit::Writer.new(io, type).write(obj)
  reader = Transit::Reader.new(type)
  reader.read(StringIO.new(io.string))
end

def round_trips(label, obj, type, opts={})
  it "round trips #{label} at top level", :focus => !!opts[:focus], :pending => opts[:pending] do
    if Time === obj
      # Our format truncates down to millis, which to_i gives us
      assert { round_trip(obj, type).to_i == obj.to_i }
    else
      assert { round_trip(obj, type) == obj }
    end
  end

  case obj
  when Time
    it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
      # Our format truncates down to millis, which to_i gives us
      before = {obj => 0}
      after = round_trip(before, type)
      assert { before.keys.first.to_i == after.keys.first.to_i }
    end
  when Hash, Array, Transit::TransitList, Set, Transit::TypedArray, Transit::CMap
  else
    it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
      assert { round_trip({obj => 0}, type) == {obj => 0} }
    end
  end

  it "round trips #{label} as a collection value", :focus => !!opts[:focus], :pending => opts[:pending] do
    if Time === obj
      # Our format truncates down to millis, which to_i gives us
      before = {a: obj}
      after = round_trip(before, type)
      assert { before.values.first.to_i == after.values.first.to_i }
    else
      assert { round_trip({a: obj}, type) == {a: obj} }
    end
  end
end

module Transit
  shared_examples "round trips" do |type|
    round_trips("nil", nil, type)
    round_trips("a keyword", :foo, type)
    round_trips("a string", "this string", type)
    round_trips("a string starting with ~", "~this string", type)
    round_trips("a string starting with ^", "^!", type)
    round_trips("a string starting with `", "`%", type)
    round_trips("true", true, type)
    round_trips("false", false, type)
    round_trips("an int", 1, type)
    round_trips("a long", 123456789012345, type)
    round_trips("a very big num", 123456789012345679012345678890, type)
    round_trips("a float", 1234.56, type)
    round_trips("a bigdec", BigDecimal.new("123.45"), type)
    round_trips("an instant (Time)", Time.now.utc, type)
    round_trips("a uuid", UUID.new, type)
    round_trips("a uri (url)", URI("http://example.com"), type)
    round_trips("a uri (file)", URI("file:///path/to/file.txt"), type)
    round_trips("a bytearray", ByteArray.new("abcdef\n\r\tghij"), type)
    round_trips("a TransitSymbol", TransitSymbol.new("abc"), type)
    round_trips("a list", TransitList.new([1,2,3]), type)
    round_trips("a hash w/ stringable keys", {"this" => "~hash", "1" => 2}, type)
    round_trips("a set", Set.new([1,2,3]), type)
    round_trips("an array", [1,2,3], type)
    round_trips("an array of ints", TypedArray.new("ints", [1,2,3]), type)
    round_trips("an array of longs", TypedArray.new("longs", [1,2,3]), type)
    round_trips("an array of floats", TypedArray.new("floats", [1.1,2.2,3.3]), type)
    round_trips("an array of floats", TypedArray.new("doubles", [1.1,2.2,3.3]), type)
    round_trips("an array of floats", TypedArray.new("bools", [true,false,false,true]), type)
    round_trips("an array of maps w/ cacheable keys", [{"this" => "a"},{"this" => "b"}], type)
    round_trips("a char", Char.new("x"), type)
    # round_trips("an extension scalar", nil, type)
    # round_trips("an extension struct", nil, type)
    round_trips("a hash with simple values", {'a' => 1, 'b' => 2, 'name' => 'russ'}, type)
    round_trips("a hash with TransitSymbols", {TransitSymbol.new("foo") => TransitSymbol.new("bar")}, type)
    round_trips("a hash with 53 bit ints",  {2**53-1 => 2**53-2}, type)
    round_trips("a hash with 54 bit ints",  {2**53   => 2**53+1}, type)
    round_trips("a cmap", CMap.new({a: :b, c: :d}), type)
  end

  describe "Transit using json" do
    include_examples "round trips", :json
  end
end
