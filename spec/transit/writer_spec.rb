require 'spec_helper'

module Transit
  describe Writer do
    let(:io) { StringIO.new }
    let(:writer) { Writer.new(io, :json) }

    describe "ground nodes at the top level" do
      it "marshals nil" do
        writer.write(nil)
        assert { io.string == '{"~#\'":null}' }
      end

      it "marshals a keyword (Ruby Symbol)" do
        writer.write(:this)
        assert { io.string == '{"~#\'":"~:this"}' }
      end

      it "marshals a namespaced keyword (Ruby Symbol)" do
        writer.write(:"namespace/name")
        assert { io.string == '{"~#\'":"~:namespace/name"}' }
      end

      it "marshals a string" do
        writer.write("this")
        assert { io.string == '{"~#\'":"this"}' }
      end

      it "marshals strings that require escaping" do
        writer.write("~this")
        writer.write("^this")
        writer.write("`this")
        assert { io.string == '{"~#\'":"~~this"}{"~#\'":"~^this"}{"~#\'":"~`this"}' }
      end

      it "marshals true" do
        writer.write(true)
        assert { io.string == '{"~#\'":true}' }
      end

      it "marshals false" do
        writer.write(false)
        assert { io.string == '{"~#\'":false}' }
      end

      it "marshals a 53 bit int as itself" do
        writer.write(2**53 - 1)
        assert { JSON.parse(io.string).values.first == 9007199254740991 }
      end

      it "marshals a 54 bit int as a tagged string" do
        writer.write(2**53)
        assert { io.string == '{"~#\'":"~i9007199254740992"}' }
      end

      it "marshals a float" do
        writer.write(37.42)
        assert { io.string == '{"~#\'":37.42}' }
      end

      it "marshals a BigDecimal" do
        writer.write(BigDecimal.new("37.42", 2))
        assert { io.string == '{"~#\'":"~f37.42"}' }
      end

      it "marshals an instant" do
        t = Time.now
        writer.write(t)
        assert { io.string == "{\"~#'\":\"~t#{t.strftime("%FT%H:%M:%S.%LZ")}\"}" }
      end

      it "marshals a UUID" do
        uuid = UUID.new
        writer.write(uuid)
        assert { io.string == "{\"~#'\":\"~u#{uuid}\"}" }
      end

      it "marshals a URI" do
        writer.write(URI("http://example.com"))
        assert { io.string == '{"~#\'":"~rhttp://example.com"}' }
      end

      it "marshals a binary object (ByteArray)" do
        ba = ByteArray.new('abcdef\n\r\tghij')
        writer.write(ba)
        assert { io.string == "{\"~#'\":\"~b#{Regexp.escape(ba.to_base64)}\"}" }
      end

      it "marshals a symbol (TransitSymbol)" do
        writer.write(TransitSymbol.new("abc"))
        assert { io.string == '{"~#\'":"~$abc"}' }
      end

      it "marshals a char" do
        char = Char.new('a')
        writer.write(char)
        assert { io.string == '{"~#\'":"~ca"}' }
      end

      it "marshals an extension scalar"
      it "marshals an extension struct"
    end

    describe "sequences" do
      it "marshals a vector (Array) with one element" do
        writer.write([1])
        assert { io.string == "[1]" }
      end

      it "marshals a vector (Array) with several elements including nesting" do
        writer.write([1, "2", [3, ["~4"]]])
        assert { io.string == "[1,\"2\",[3,[\"~~4\"]]]" }
      end

      it "marshals a set" do
        writer.write(Set.new([1,"2","~3",:four]))
        assert { io.string == '{"~#set":[1,"2","~~3","~:four"]}' }
      end

      it "marshals a list" do
        writer.write(TransitList.new([1,"2","~3",:four]))
        assert { io.string == '{"~#list":[1,"2","~~3","~:four"]}' }
      end

      it "marshals a typed int array" do
        writer.write(TypedArray.new(:ints, [1,2,3]))
        assert { io.string == '{"~#ints":[1,2,3]}' }
      end

      it "marshals a typed long array with 53 bit ints" do
        writer.write(TypedArray.new(:longs, [2**53 - 2, 2**53 - 1]))
        assert { io.string == '{"~#longs":[9007199254740990,9007199254740991]}' }
      end

      it "marshals a typed long array with 54 bit ints (tagged)" do
        writer.write(TypedArray.new(:longs, [2**53, 2**53 + 1]))
        assert { io.string == '{"~#longs":["~i9007199254740992","~i9007199254740993"]}' }
      end

      it "marshals a typed float array" do
        writer.write(TypedArray.new(:floats, [1.1,2.2,3.3]))
        assert { io.string == '{"~#floats":[1.1,2.2,3.3]}' }
      end

      it "marshals a typed double array" do
        writer.write(TypedArray.new(:doubles, [1.1,2.2,3.3]))
        assert { io.string == '{"~#doubles":[1.1,2.2,3.3]}' }
      end

      it "marshals a typed bool array" do
        writer.write(TypedArray.new(:bools, [true, false, true]))
        assert { io.string == '{"~#bools":[true,false,true]}' }
      end

      it "marshals a cmap" do
        writer.write(CMap.new({{a: 1} => :b, [1,"~foo"] => 3, {c: {d: :e}} => :f}))
        assert { io.string == '{"~#cmap":[{"~:a":1},"~:b",[1,"~~foo"],3,{"~:c":{"~:d":"~:e"}},"~:f"]}' }
      end
    end

    describe "hash keys" do
      def self.marshals_map_with_key(label, value, as_key)
        it "marshals #{label} as a key" do
          writer.write({value => 0})
          writer.write({"nested" => {value => 0}})
          assert { io.string == "{#{as_key.inspect}:0}{\"nested\":{#{as_key.inspect}:0}}" }
        end
      end

      marshals_map_with_key("nil", nil, "~_")
      marshals_map_with_key("a keyword", :this, "~:this")
      marshals_map_with_key("a string (as/is)", "this", "this")
      it "marshals strings that requires escaping as keys" do
        writer.write({"~this" => 0})
        writer.write({"^this" => 0})
        writer.write({"`this" => 0})
        assert { io.string == '{"~~this":0}{"~^this":0}{"~`this":0}' }
      end
      marshals_map_with_key("true", true, "~?t")
      marshals_map_with_key("false", false, "~?f")
      marshals_map_with_key("a 53 bit int", 2**53 - 1, "~i9007199254740991")
      marshals_map_with_key("a 54 bit int", 2**53,     "~i9007199254740992")
      marshals_map_with_key("a float", 42.37, "~d42.37")
      marshals_map_with_key("a BigDecimal", BigDecimal.new("42.37"), "~f42.37")
      it "marshals an instant as a key" do
        t = Time.now
        writer.write({t => "ignore"})
        assert { io.string == "{\"~t#{t.strftime("%FT%H:%M:%S.%LZ")}\":\"ignore\"}" }
      end
      marshals_map_with_key("a uuid", UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7"), "~udda5a83f-8f9d-4194-ae88-5745c8ca94a7")
      marshals_map_with_key("a uri", URI("http://example.com"), "~rhttp://example.com")
      marshals_map_with_key("symbol", TransitSymbol.new("foo"), "~$foo" )
      marshals_map_with_key("char", Char.new("a"), "~ca")
      # marshals_map_with_key("an extension scalar (tagged string) ", , )
      # it "raises when trying to set a vector as a key"
      # it "raises when trying to set a dict (Hash) as a key"
      # it "raises when trying to set a set as a key"
      # it "raises when trying to set a list as a key"
      # it "raises when trying to set a typed array as a key"
      # it "raises when trying to set an extension scalar (tagged map) as a key"
      # it "raises when trying to set an extension struct (tagged map) as a key"
    end

    describe "hash values" do
      def self.marshals_map_with_value(label, value, rep)
        it "marshals #{label} as a map value" do
          writer.write({"a" => value})
          writer.write({"nested" => {"a" => value}})
          assert { io.string == "{\"a\":#{rep}}{\"nested\":{\"a\":#{rep}}}" }
        end
      end

      marshals_map_with_value("nil", nil, "null")
      marshals_map_with_value("a keyword", :this, '"~:this"')
      marshals_map_with_value("a string (as/is)", "this", '"this"')
      it "marshals strings that requires escaping as values" do
        writer.write({"a" => "~this"})
        writer.write({"b" => "^this"})
        writer.write({"c" => "`this"})
        assert { io.string == '{"a":"~~this"}{"b":"~^this"}{"c":"~`this"}' }
      end

      marshals_map_with_value("true", true, true)
      marshals_map_with_value("false", false, false)
      marshals_map_with_value("a 53 bit int", 2**53 - 1, 9007199254740991)
      marshals_map_with_value("a 54 bit int", 2**53, '"~i9007199254740992"')
      marshals_map_with_value("a float", 42.37, 42.37)
      marshals_map_with_value("a BigDecimal", BigDecimal.new("42.37"), '"~f42.37"')

      it "marshals an instant as a value" do
        t = Time.now
        writer.write({"a" => t})
        assert { io.string == "{\"a\":\"~t#{t.strftime("%FT%H:%M:%S.%LZ")}\"}" }
      end
      marshals_map_with_value("a uuid", UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7"), '"~udda5a83f-8f9d-4194-ae88-5745c8ca94a7"')
      marshals_map_with_value("a uri", URI("http://example.com"), '"~rhttp://example.com"')
      marshals_map_with_value("symbol", TransitSymbol.new("foo"), '"~$foo"' )
      marshals_map_with_value("char", Char.new("a"), '"~ca"')
    end

    describe "nested structures" do
      it "marshals a nested data structure within a map" do
        writer.write({a: [1, [{b: "~c"}]]})
        assert { io.string == "{\"~:a\":[1,[{\"~:b\":\"~~c\"}]]}" }
      end

      it "marshals a nested data structure within an array" do
        writer.write([37, {a: [1, [{b: "~c"}]]}])
        assert { io.string == "[37,{\"~:a\":[1,[{\"~:b\":\"~~c\"}]]}]" }
      end
    end

    describe "caching" do
      it "caches a simple string as map key" do
        writer.write([{"this" => "a"},{"this" => "b"}])
        assert { io.string == '[{"this":"a"},{"^!":"b"}]' }
      end

      it "caches keys in an array" do
        writer.write([:key1, :key1])
        assert { io.string == '["~:key1","^!"]' }
      end
    end
  end
end
