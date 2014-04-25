require 'spec_helper'

module Transit
  describe Writer do
    let(:io) { StringIO.new }
    let(:writer) { Writer.new(io, :json) }


    describe "map keys" do
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
        assert { io.string == "{\"~t#{t.utc.iso8601(3)}\":\"ignore\"}" }
      end
      it "doesn't modify the source Time when writing an instant as a map key" do
        t = Time.now
        z = t.zone
        writer.write({t => :now})
        assert { t.zone == z }
      end
      marshals_map_with_key("a uuid", UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7"), "~udda5a83f-8f9d-4194-ae88-5745c8ca94a7")
      marshals_map_with_key("a uri", URI("http://example.com"), "~rhttp://example.com")
      marshals_map_with_key("symbol", TransitSymbol.new("foo"), "~$foo" )
      marshals_map_with_key("char", Char.new("a"), "~ca")

      it "marshals an extension scalar (tagged string) as a map key" do
        writer = Writer.new(io, :json)
        writer.register(Date, DateHandler)
        writer.write({Date.new(1963,11,26) => :david})
        assert { io.string ==  "{\"~D1963-11-26\":\"~:david\"}" }
      end

      it "marshals a map with composite keys" do
        writer.write({{"a" => "map", "as" => "key"} => "a value" })
        assert { io.string == '{"~#cmap":[{"a":"map","as":"key"},"a value"]}' }
      end

      # it "raises when trying to set a vector as a key"
      # it "raises when trying to set a dict (Hash) as a key"
      # it "raises when trying to set a set as a key"
      # it "raises when trying to set a list as a key"
      # it "raises when trying to set a typed array as a key"
      # it "raises when trying to set an extension scalar (tagged map) as a key"
      # it "raises when trying to set an extension struct (tagged map) as a key"
    end

    describe "collection values" do
      def self.marshals_collection_with_value(label, value, rep, focus=false)
        it "marshals #{label} as a map value", :focus => focus do
          writer.write({"a" => value})
          writer.write({"nested" => {"a" => value}})
          assert { io.string == "{\"a\":#{rep}}{\"nested\":{\"a\":#{rep}}}" }
        end
        it "marshals #{label} as an array value", :focus => focus do
          writer.write([value])
          writer.write([[value]])
          assert { io.string == "[#{rep}][[#{rep}]]" }
        end
      end

      marshals_collection_with_value("nil", nil, "null")
      marshals_collection_with_value("a keyword", :this, '"~:this"')
      marshals_collection_with_value("a string (as/is)", "this", '"this"')

      it "marshals a string that requires escaping a map value" do
        writer.write({"a" => "~this"})
        writer.write({"b" => "^this"})
        writer.write({"c" => "`this"})
        assert { io.string == '{"a":"~~this"}{"b":"~^this"}{"c":"~`this"}' }
      end

      it "marshals a string that requires escaping an array value" do
        writer.write(["~this","^this","`this"])
        assert { io.string == '["~~this","~^this","~`this"]' }
      end

      marshals_collection_with_value("true", true, true)
      marshals_collection_with_value("false", false, false)
      marshals_collection_with_value("a float", 42.37, 42.37)
      marshals_collection_with_value("a BigDecimal", BigDecimal.new("42.37"), '"~f42.37"')

      it "marshals an instant as a map value" do
        t = Time.now
        writer.write({"a" => t})
        assert { io.string == "{\"a\":\"~t#{t.utc.iso8601(3)}\"}" }
      end

      it "marshals an instant as an array value" do
        t = Time.now
        writer.write([t])
        assert { io.string == "[\"~t#{t.utc.iso8601(3)}\"]" }
      end

      marshals_collection_with_value("a uuid", UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7"), '"~udda5a83f-8f9d-4194-ae88-5745c8ca94a7"')
      marshals_collection_with_value("a uri", URI("http://example.com"), '"~rhttp://example.com"')
      marshals_collection_with_value("symbol", TransitSymbol.new("foo"), '"~$foo"' )
      marshals_collection_with_value("char", Char.new("a"), '"~ca"')


      marshals_collection_with_value("an array", [1,2,3], '[1,2,3]')
      marshals_collection_with_value("a map", {a: :b}, '{"~:a":"~:b"}')
      marshals_collection_with_value("a set", Set.new([1,2,3]), '{"~#set":[1,2,3]}')
      marshals_collection_with_value("a list", TransitList.new([1,2,3]), '{"~#list":[1,2,3]}')
      marshals_collection_with_value("an array of ints", IntsArray.new([1,2,3]), '{"~#ints":[1,2,3]}')
      marshals_collection_with_value("an array of ints", LongsArray.new([1,2,3]), '{"~#longs":[1,2,3]}')
      marshals_collection_with_value("an array of ints", FloatsArray.new([1.1,2.2,3.3]), '{"~#floats":[1.1,2.2,3.3]}')
      marshals_collection_with_value("an array of ints", DoublesArray.new([1.1,2.2,3.3]), '{"~#doubles":[1.1,2.2,3.3]}')
      marshals_collection_with_value("an array of ints", BoolsArray.new([true,false,true]), '{"~#bools":[true,false,true]}')

      it "marshals a map with composite keys as map value" do
        writer.write({:a => {{:b => :c} => :e}})
        assert { io.string == '{"~:a":{"~#cmap":[{"~:b":"~:c"},"~:e"]}}' }
      end

      it "marshals a map with composite keys as array value" do
        writer.write([{{:b => :c} => :e}])
        assert { io.string == '[{"~#cmap":[{"~:b":"~:c"},"~:e"]}]' }
      end

      it "marshals an extension scalar as a map value" do
        writer = Writer.new(io, :json)
        writer.register(Date, DateHandler)
        writer.write({Date.new(2014,1,2) => Date.new(2014,1,3)})
        assert { io.string == "{\"~D2014-01-02\":\"~D2014-01-03\"}" }
      end

      it "marshals an extension scalar as a map value" do
        writer = Writer.new(io, :json)
        writer.register(Date, DateHandler)
        writer.write([Date.new(2014,1,2)])
        assert { io.string == "[\"~D2014-01-02\"]" }
      end

      it "marshals an extension struct as a map value"
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
  end
end
