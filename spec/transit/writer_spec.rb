require 'spec_helper'

module Transit
  describe JsonWriter do
    let(:io) { StringIO.new }
    let(:writer) { Writer.new(io, :json) }

    describe "leaf nodes" do
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

      it "marshals a map w/ string keys and values that require escaping" do
        writer.write({"~a" => 1, "~b" => "~c"})
        assert { io.string == "{\"~~a\":1,\"~~b\":\"~~c\"}" }
      end

      it "marshals a map w/ Symbol keys and vals" do
        writer.write({:a => 1, b: :c})
        assert { io.string == "{\"~:a\":1,\"~:b\":\"~:c\"}" }
      end

      it "marshals a map w/ time keys" do
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
    end
  end
end
