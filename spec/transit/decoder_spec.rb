require 'spec_helper'

module Transit
  describe Decoder do
    let(:cache) { RollingCache.new }

    def decode(o)
      Decoder.new.decode(o, cache)
    end

    [nil, true, false].each do |element|
      it "decodes #{element.inspect} to itself" do
        assert { decode(element) == element }
      end
    end

    it 'decodes an int to itself' do
      assert { decode(1) == 1 }
    end

    it 'decodes a BigDecimal' do
      assert { decode("~f123.456") == BigDecimal.new("123.456") }
    end

    it 'decodes a one-pair hash with simple values' do
      assert { decode({a: 1}) == {a: 1} }
    end

    it 'decodes an ordinary hash with an encoded key' do
      assert { decode({'~~escaped' => 37}) == {'~escaped' => 37} }
      assert { decode({'~~escaped' => 37, a: 42}) == {'~escaped' => 37, a: 42} }
    end

    it 'decodes an ordinary hash with an encoded value' do
      assert { decode({a: '~~escaped'}) == {a: '~escaped'} }
      assert { decode({a: '~~escaped', b: 42}) == {a: '~escaped', b: 42} }
    end

    it 'decodes strings' do
      assert { decode("foo") == "foo" }
    end

    it 'decodes an empty array' do
      assert { decode([]) == [] }
    end

    it 'decodes an array of simple values' do
      assert { decode([1,2,3,2,4]) == [1,2,3,2,4] }
    end

    it 'decodes an array of cacheables' do
      assert { decode(["~:key1", "^!"]) == [:key1, :key1] }
    end

    describe "tagged hashes" do
      it 'decodes sets' do
        assert { decode({"~#set" => [1,2,3,2,4]}) == Set.new([1,2,3,4]) }
      end

      it 'decodes nested sets' do
        assert { decode({"~#set" => [{"~#set" => [1,2,3,2,4]}]}) == Set.new([Set.new([1,2,3,4])]) }
      end

      it 'decodes lists' do
        assert { decode({"~#list" => [1,2,3,2,4]}) == TransitList.new([1,2,3,2,4]) }
      end

      it 'decodes nested lists' do
        assert { decode({"~#list" => {"^!" => [1,2,3]}}) == TransitList.new(TransitList.new([1,2,3]))}
      end
    end

    describe "tagged strings" do
      it 'decodes keywords to Ruby symbols' do
        assert { decode("~:foo") == :foo }
      end

      it 'unescapes escaped strings' do
        assert { decode("~~foo") == "~foo" }
      end

      it 'decodes TransitSymbol into the Ruby version of Clojure symbols' do
        assert { decode("~$foo") == TransitSymbol.new("foo") }
      end

      it 'decodes base64 strings into ByteArray' do
        assert { decode("~bYWJj\n").is_a? ByteArray }
        assert { decode("~bYWJj\n").to_s ==
          Base64.decode64("YWJj\n") }
      end

      it 'decodes instants to Time objects' do
        assert { decode("~t1985-04-12T23:20:50.052Z") ==
          Time.parse("1985-04-12T23:20:50.052Z") }

        assert { decode("~t1985-04-12T23:20:50.052Z").usec == 52000 }

        assert { decode({"~#t" => "1985-04-12T23:20:50.052Z"}) ==
          Time.parse("1985-04-12T23:20:50.052Z") }
      end

      it 'decodes uuids' do
        assert { decode("~ub54adc00-67f9-11d9-9669-0800200c9a66").is_a? UUID }
        assert { decode("~ub54adc00-67f9-11d9-9669-0800200c9a66") ==
          Transit::UUID.new("b54adc00-67f9-11d9-9669-0800200c9a66") }
      end

      it 'decodes uris' do
        assert { decode("~rprotocol://domain") == URI("protocol://domain") }
      end

      it 'decodes chars' do
        assert {decode("~ca") == Char.new("a")}
      end
    end

    describe 'nested data' do
      it 'decodes an array of tagged strings' do
        [["~:kw",      :kw],
         ["~$cs",      TransitSymbol.new("cs")],
         ["~f123.456", 123.456],
         ["~d3.14158", 3.14158]].map do |encoded, decoded|
          assert { decode(encoded) == decoded }
        end
      end

      it 'decodes nested hashes' do
        assert { decode({a: 1, b: 2, c: {d: 3}}) == {a: 1, b: 2, c: {d: 3}} }
      end
    end

    describe 'registration' do
      it 'requires a 1-arg lambda' do
        assert { rescuing { Decoder.new.register("~D") {|s,t|} }.
          message =~ /arity/ }
      end

      describe 'overrides' do
        it 'supports override of default string decoders' do
          decoder = Decoder.new
          decoder.register("~r") {|u| "DECODED: #{u}"}
          assert { decoder.decode("~rhttp://foo.com", cache) == "DECODED: http://foo.com" }
        end

        it 'supports override of default hash decoders' do
          my_uuid_class = Class.new(String)
          decoder = Decoder.new
          my_uuid = my_uuid_class.new(UUID.new.to_s)

          decoder.register("~#u") {|u| my_uuid_class.new(u)}
          assert { decoder.decode({"~#u" => my_uuid.to_s}, cache) == my_uuid }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          decoder = Decoder.new
          decoder.register("~D") {|s| Date.parse(s[2..-1])}
          assert { decoder.decode("~D2014-03-15", cache) == Date.new(2014,3,15) }
        end

        it 'supports hash based extensions' do
          decoder = Decoder.new
          decoder.register("~#Xdouble") {|d| d * 2}
          assert { decoder.decode({"~#Xdouble" => 44}, cache) == 88 }
        end

        it 'supports hash based extensions that return nil'  do
          decoder = Decoder.new
          decoder.register("~#Xmynil") {|_| nil}
          assert { decoder.decode({"~#Xmynil" => :anything }, cache) == nil }
        end

        it 'supports hash based extensions that return false' do
          decoder = Decoder.new
          decoder.register("~#Xmyfalse") {|_| false}
          assert { decoder.decode({"~#Xmyfalse" => :anything }, cache) == false }
        end
      end
    end

    describe "caching" do
      it "decodes cacheable map keys" do
        assert { decode([{"this" => "a"},{"^!" => "b"}]) == [{"this" => "a"},{"this" => "b"}] }
      end

      it "does not cache non-map-keys" do
        assert { decode([{"a" => "~^!"},{"b" => "~^?"}]) == [{"a" => "^!"},{"b" => "^?"}] }
      end
    end
  end
end
