require 'spec_helper'

module Transit
  describe Marshaler do
    let(:marshaler) { TransitMarshaler.new }

    shared_examples "top level" do |label, input, output|
      it "marshals #{label} (quoted for json)" do
        marshaler = TransitMarshaler.new(:quote_scalars => true)
        marshaler.marshal_top(input)
        assert { marshaler.value == {"~#'" => output } }
      end

      it "marshals #{label} (unquoted for msgpack)" do
        marshaler = TransitMarshaler.new(:quote_scalars => false)
        marshaler.marshal_top(input)
        assert { marshaler.value == output }
      end
    end

    describe "top level scalars" do
      include_examples "top level", "nil", nil, nil
      include_examples "top level", "a keyword", :this, "~:this"
      include_examples "top level", "a namespaced keyword", :"namespace/name", "~:namespace/name"
      include_examples "top level", "a string", "this", "this"
      include_examples "top level", "a string that starts with ~", "~this", "~~this"
      include_examples "top level", "a string that starts with ^", "^this", "~^this"
      include_examples "top level", "a string that starts with `", "`this", "~`this"
      include_examples "top level", "true", true, true
      include_examples "top level", "false", false, false
      include_examples "top level", "a float", 37.42, 37.42
      include_examples "top level", "a BigDecimal", BigDecimal.new("37.42", 2), "~f37.42"
      include_examples "top level", "a Date", Date.new(2014,1,2), "~t2014-01-02T00:00:00.000Z"
      #    include_examples "top level", "a Time", Time.new(2014,1,2,3,4,5.678,"+00:00"), "~t2014-01-02T03:04:05.678Z"
      include_examples "top level", "a DateTime", DateTime.new(2014,1,2,3,4,5.678,"+00:00"), "~t2014-01-02T03:04:05.678Z"
      include_examples "top level", "a UUID", UUID.new("b1502078-57ed-40d1-a54c-0f4ba2e74b37"), "~ub1502078-57ed-40d1-a54c-0f4ba2e74b37"
      include_examples "top level", "a URI", URI("http://example.com"), "~rhttp://example.com"
      include_examples "top level", "an Addressable::URI", Addressable::URI.parse("http://example.com"), "~rhttp://example.com"
      include_examples "top level", "a binary object (ByteArray)", ByteArray.new('abcdef\n\r\tghij'), "~bYWJjZGVmXG5cclx0Z2hpag==\n"
      include_examples "top level", "a TransitSymbol", TransitSymbol.new("abc"), "~$abc"
      include_examples "top level", "a Char", Char.new("a"), "~ca"
    end

    describe "sequences" do
      it "marshals a vector (Array) with one element" do
        marshaler.marshal_top([1])
        assert { marshaler.value == [1] }
      end

      it "marshals a vector (Array) with several elements including nesting" do
        marshaler.marshal_top([1, "2", [3, ["~4"]]])
        assert { marshaler.value == [1,"2",[3,["~~4"]]] }
      end

      it "marshals a set" do
        marshaler.marshal_top(Set.new([1,"2","~3",:four]))
        assert { marshaler.value == {"~#set" => [1,"2","~~3","~:four"]} }
      end

      it "marshals a list" do
        marshaler.marshal_top(TransitList.new([1,"2","~3",:four]))
        assert { marshaler.value == {"~#list" => [1,"2","~~3","~:four"]} }
      end

      it "marshals a typed int array" do
        marshaler.marshal_top(IntsArray.new([1,2,3]))
        assert { marshaler.value == {"~#ints" => [1,2,3]} }
      end

      it "marshals a typed float array" do
        marshaler.marshal_top(FloatsArray.new([1.1,2.2,3.3]))
        assert { marshaler.value == {"~#floats" => [1.1,2.2,3.3]} }
      end

      it "marshals a typed double array" do
        marshaler.marshal_top(DoublesArray.new([1.1,2.2,3.3]))
        assert { marshaler.value == {"~#doubles" => [1.1,2.2,3.3]} }
      end

      it "marshals a typed bool array" do
        marshaler.marshal_top(BoolsArray.new([true, false, true]))
        assert { marshaler.value == {"~#bools" => [true,false,true]} }
      end
    end


    describe "hashes" do
      it 'marshals a map' do
        marshaler.marshal_top({"a" => 1})
        assert { marshaler.value == {"a" => 1} }
      end

      it 'marshals a nested map' do
        marshaler.marshal_top({"a" => {"b" => 1}})
        assert { marshaler.value == {"a" => {"b" => 1}} }
      end

      it 'marshals a big mess' do
        input   = {"~a" => [1, {:b => [2,3]}, 4]}
        output  = {"~~a" => [1, {"~:b" => [2,3]}, 4]}
        marshaler.marshal_top(input)
        assert { marshaler.value == output }
      end
    end

    describe "unrecognized encodings" do
      it 'marshals a ` encoded string without the `' do
        marshaler =  TransitMarshaler.new(:quote_scalars => false)
        marshaler.marshal_top("`~xfoo")
        assert { marshaler.value == "~xfoo" }
      end

      it 'marshals a TaggedValue' do
        marshaler =  TransitMarshaler.new
        marshaler.marshal_top(TaggedValue.new("~#unrecognized", [:a, 1]))
        assert { marshaler.value == {"~#unrecognized" => ["~:a", 1]} }
      end
    end

    describe "json-specific rules" do
      it 'marshals Time as a string' do
        t = Time.new(2014,1,2,3,4,5.12345,"-05:00")
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(t)
        assert { marshaler.value == "~t2014-01-02T08:04:05.123Z" }
      end

      it 'marshals DateTime as a string' do
        dt = DateTime.new(2014,1,2,3,4,5.1235,"-5")
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(dt)
        assert { marshaler.value == "~t2014-01-02T08:04:05.123Z" }
      end

      it 'marshals a Date as a string' do
        t = Date.new(2014,1,2)
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(t)
        assert { marshaler.value == "~t2014-01-02T00:00:00.000Z" }
      end

      it 'marshals 2**53 as an int' do
        marshaler = TransitMarshaler.new(:max_int => JsonMarshaler::JSON_MAX_INT)
        marshaler.marshal_top(2**53)
        assert { marshaler.value == 2**53 }
      end

      it 'marshals 2**53 + 1 as an encoded string' do
        marshaler = TransitMarshaler.new(:max_int => JsonMarshaler::JSON_MAX_INT)
        marshaler.marshal_top(2**53 + 1)
        assert { marshaler.value == "~i#{2**53+1}" }
      end

      it 'marshals -2**53 as an int' do
        marshaler = TransitMarshaler.new(:min_int => JsonMarshaler::JSON_MIN_INT)
        marshaler.marshal_top(-2**53)
        assert { marshaler.value == -2**53 }
      end

      it 'marshals -(2**53 + 1) as an encoded string' do
        marshaler = TransitMarshaler.new(:min_int => JsonMarshaler::JSON_MIN_INT)
        marshaler.marshal_top(-(2**53 + 1))
        assert { marshaler.value == "~i-#{2**53+1}" }
      end

      it 'marshals a UUID as an encoded string' do
        uuid = UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7")
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(uuid)
        assert { marshaler.value == "~udda5a83f-8f9d-4194-ae88-5745c8ca94a7" }
      end
    end

    describe "msgpack-specific rules" do
      it 'marshals Time as a map' do
        t = Time.now
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(t)
        assert { marshaler.value == {"~#t" => DateTimeUtil.to_millis(t)} }
      end

      it 'marshals DateTime as a map' do
        dt = DateTime.now
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(dt)
        assert { marshaler.value == {"~#t" => DateTimeUtil.to_millis(dt)} }
      end

      it 'marshals a Date as a map' do
        d = Date.new(2014,1,2)
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(d)
        assert { marshaler.value == {"~#t" => DateTimeUtil.to_millis(d) } }
      end

      it 'marshals 2**64 - 1 as an int' do
        marshaler = TransitMarshaler.new(:max_int => MessagePackMarshaler::MSGPACK_MAX_INT)
        marshaler.marshal_top(2**64-1)
        assert { marshaler.value == 2**64-1 }
      end

      it 'marshals 2**64 as an encoded string' do
        marshaler = TransitMarshaler.new(:max_int => MessagePackMarshaler::MSGPACK_MAX_INT)
        marshaler.marshal_top(2**64)
        assert { marshaler.value == "~i#{2**64}" }
      end

      it 'marshals -2**63 as an int' do
        marshaler = TransitMarshaler.new(:min_int => MessagePackMarshaler::MSGPACK_MIN_INT)
        marshaler.marshal_top(-2**63)
        assert { marshaler.value == -2**63 }
      end

      it 'marshals -(2**63 + 1) as an encoded string' do
        marshaler = TransitMarshaler.new(:min_int => MessagePackMarshaler::MSGPACK_MIN_INT)
        marshaler.marshal_top(-(2**63 + 1))
        assert { marshaler.value == "~i-#{2**63+1}" }
      end

      it 'marshals a UUID as a string in an encoded hash' do
        msb, lsb = 6353693437827696322, 11547645107031845111
        uuid = UUID.new(msb,lsb)
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(uuid)
        assert { marshaler.value == {"~#u" => [msb,lsb].map{|i| "~i#{i}"}} }
      end
    end

    describe "edge cases" do
      it "writes Chars with escape characters" do
        chars = %w[` ~ ^ #].map {|c| Char.new(c)}
        marshaler.marshal_top(chars)
        assert { marshaler.value == ["~c~`", "~c~~", "~c~^", "~c#"] }
      end
    end

    describe "extensions" do
      it "marshals an extension scalar" do
        marshaler.register(Date, DateHandler)
        marshaler.marshal_top(Date.new(2014,1,2))
        assert { marshaler.value == "~D2014-01-02" }
      end

      it "marshals an extension struct" do
        marshaler.register(Person, PersonHandler)
        marshaler.marshal_top(Person.new("Joe", "Smith", Date.new(1963,11,26)))
        assert { marshaler.value == {"~#person" => {
              "~:first_name"=>"Joe",
              "~:last_name"=>"Smith",
              "~:birthdate"=>"~t1963-11-26T00:00:00.000Z"}}}
      end
    end

    describe "caching" do
      it "caches a simple string as map key" do
        marshaler.marshal_top([{"this" => "a"},{"this" => "b"}])
        assert { marshaler.value == [{"this" => "a"}, {"^!" => "b"}] }
      end

      it "caches keys in an array" do
        marshaler.marshal_top([:key1, :key1])
        assert { marshaler.value == ["~:key1","^!"] }
      end

      it "caches tagged map keys" do
        marshaler.marshal_top(Set.new([Set.new([:a])]))
        assert { marshaler.value == {"~#set" => [{"^!" => ["~:a"]}]} }
      end

      it "caches tagged value (map) keys" do
        tv = TaggedValue.new("~#unrecognized", :value)
        marshaler.marshal_top([TaggedValue.new("~#unrecognized", :a),
                               TaggedValue.new("~#unrecognized", :b)])
        assert { marshaler.value == [{"~#unrecognized" => "~:a"},{"^!" => "~:b"}] }
      end
    end

    describe "illegal conditions" do
      it "raises when a handler provides nil as a tag" do
        handler = Class.new do
          def tag(_) nil end
        end
        marshaler.register(Date, handler)
        assert { rescuing { marshaler.marshal_top(Date.today) }.message =~ /must provide a non-nil tag/ }
      end
    end

  end
end
