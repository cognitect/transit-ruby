require 'spec_helper'

module Transit
  describe Writer do
    let(:io) { StringIO.new }
    let(:writer) { Writer.new(io, :json) }

    describe "leaf nodes" do
      it "marshals nil" do
        writer.write(nil)
        assert { io.string == "null" }
      end

      it "marshals false" do
        writer.write(false)
        assert { io.string == "false" }
      end

      it "marshals true" do
        writer.write(true)
        assert { io.string == "true" }
      end

      it "marshals a string" do
        writer.write("this")
        assert { io.string == "\"this\"" }
      end

      it "escapes a string that begins with ~" do
        writer.write("~this")
        assert { io.string == "\"~~this\"" }
      end

      it "marshals an instant" do
        t = Time.now
        writer.write(t)
        assert { io.string == "\"~t#{t.strftime("%FT%H:%M:%S.%LZ")}\"" }
      end

      it "marshals an int" do
        writer.write(37)
        assert { io.string == "37" }
      end

      it "marshals a float" do
        writer.write(37.42)
        assert { io.string == "37.42" }
      end

      it "marshals a BigDecimal" do
        writer.write(BigDecimal.new("37.42", 2))
        assert { io.string == "\"~f37.42\"" }
      end

      it "marshals an array" do
        writer.write([1])
        assert { io.string == "[1]" }
      end

      it "marshals a Ruby Symbol" do
        writer.write(:this)
        assert { io.string == "\"~:this\"" }
      end

      it "marshals a namespaced Ruby Symbol" do
        writer.write(:"namespace/name")
        assert { io.string == "\"~:namespace/name\"" }
      end

      it "marshals a TransitSymbol" do
        writer.write(TransitSymbol.new("namespace/name"))
        assert { io.string == "\"~:namespace/name\"" }
      end

      it "marshals a URI" do
        writer.write(URI("http://example.com"))
        assert { io.string == "\"~rhttp://example.com\"" }
      end

      it "marshals a ByteArray" do
        # NOTE: this is a round trip example
        bytes = ByteArray.new("abcdef\n\r\tghij")
        writer.write(bytes)
        assert { ByteArray.from_base64(Oj.load(io.string)[2..-1]) == bytes }
      end
    end

    describe "collections" do
      it "marshals an array with several elements including nested arrays" do
        writer.write([1, "2", [3, ["~4"]]])
        assert { io.string == "[1,\"2\",[3,[\"~~4\"]]]" }
      end

      it "marshals a map w/ string keys" do
        writer.write({"a" => 1, "b" => "c"})
        assert { io.string == "{\"a\":1,\"b\":\"c\"}" }
      end

      it "marshals a string that requires escaping as an encoded key" do
        writer.write({"~a" => 1, "~b" => "~c"})
        assert { io.string == "{\"~~a\":1,\"~~b\":\"~~c\"}" }
      end

      it "marshals a Ruby Symbol as an encoded key" do
        writer.write({:a => 1, b: :c})
        assert { io.string == "{\"~:a\":1,\"~:b\":\"~:c\"}" }
      end

      it "marshals a TransitSymbol as an encoded key" do
        writer.write({TransitSymbol.new(:a) => 1, TransitSymbol.new("b") => :c})
        assert { io.string == "{\"~:a\":1,\"~:b\":\"~:c\"}" }
      end

      it "marshals time as an encoded key" do
        t = Time.new(2014,1,2,3,4,5)
        writer.write({t => "ignore"})
        assert { io.string == "{\"~t2014-01-02T03:04:05.000Z\":\"ignore\"}" }
      end

      it "marshals a nested map" do
        t = Time.new(2014,1,2,3,4,5)
        writer.write({:a => { t => :ignore }})
        assert { io.string == "{\"~:a\":{\"~t2014-01-02T03:04:05.000Z\":\"~:ignore\"}}" }
      end

      it "raises for non-stringable map keys" do
        assert { rescuing { writer.write({[1,2] => "ignore"}).message =~ /Can not push/ } }
      end

      it "marshals a nested data structure within a map" do
        writer.write({a: [1, [{b: "~c"}]]})
        assert { io.string == "{\"~:a\":[1,[{\"~:b\":\"~~c\"}]]}" }
      end

      it "marshals a nested data structure within an array" do
        writer.write([37, {a: [1, [{b: "~c"}]]}])
        assert { io.string == "[37,{\"~:a\":[1,[{\"~:b\":\"~~c\"}]]}]" }
      end

      it "marshals nil as an encoded key" do
        writer.write({nil => :val})
        assert { io.string == "{\"~_\":\"~:val\"}" }
      end

      it "marshals false as an encoded key" do
        writer.write({false => :val})
        assert { io.string == "{\"~?f\":\"~:val\"}" }
      end

      it "marshals true as an encoded key" do
        writer.write({true => :val})
        assert { io.string == "{\"~?t\":\"~:val\"}" }
      end

      it "marshals a float as an encoded key" do
        writer.write({37.42 => :val})
        assert { io.string == "{\"~d37.42\":\"~:val\"}" }
      end

      it "marshals a BigDecimal as an encoded key" do
        writer.write({BigDecimal.new("37.42") => :val})
        assert { io.string == "{\"~f37.42\":\"~:val\"}" }
      end
    end
  end
end
