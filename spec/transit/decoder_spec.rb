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
      it 'decodes instants to Time objects' do
        assert { decode({"~#t" => "1985-04-12T23:20:50.052Z"}) ==
          Time.parse("1985-04-12T23:20:50.052Z") }
      end

      it 'decodes uuids' do
        assert { decode({"~#u" => "b54adc00-67f9-11d9-9669-0800200c9a66"}).is_a? UUID }
        assert { decode({"~#u" => "b54adc00-67f9-11d9-9669-0800200c9a66"}) ==
          Transit::UUID.new("b54adc00-67f9-11d9-9669-0800200c9a66") }
      end

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

      it 'decodes cmaps' do
        assert { decode({"~#cmap" => ["~:a", "b", "c", "~:d"]}) == CMap.new({:a => "b", "c" => :d}) }
      end

      it 'decodes nested cmaps' do
        cm1 = {"~#cmap" => ["~:a", "~:b"]}
        cm2 = {"~#cmap" => ["~:c", "~:d"]}
        cm3 = {"~#cmap" => [cm1, cm2]}
        assert { decode(cm3) == CMap.new({CMap.new({:a => :b}) => CMap.new({:c => :d})}) }
      end
    end

    describe "tagged strings" do
      it 'decodes BigDecimals' do
        assert { decode("~f123.456") == BigDecimal.new("123.456") }
      end

      it 'decodes tagged ints' do
        assert { decode("~i9007199254740992") == 9007199254740992 }
      end

      it 'decodes keywords to Ruby symbols' do
        assert { decode("~:foo") == :foo }
      end

      it 'unescapes escaped strings' do
        assert { decode("~~foo") == "~foo" }
        assert { decode("~^foo") == "^foo" }
        assert { decode("~`foo") == "`foo" }
      end

      it 'decodes TransitSymbols' do
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
