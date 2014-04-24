require 'spec_helper'

module Transit
  describe Decoder do
    def decode(o)
      Decoder.new.decode(o)
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

    example do
      assert { decode({"~#set" => [{"^!" => [nil, "~~eight"]}]}) == Set.new([Set.new([nil, "~eight"])]) }
    end

    it 'decodes strings' do
      assert { decode("foo") == "foo" }
    end

    it '_encodes_ strings it does not know how to decode' do
      assert { decode("~xfoo") == "`~xfoo" }
      assert { decode(["~xfoo", "~xbar"]) == ["`~xfoo", "`~xbar"] }
      assert { decode({"~xfoo" => "~xbar"}) == {"`~xfoo" => "`~xbar"} }
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
      it 'decodes instants to DateTime objects' do
        expected = DateTime.parse("1985-04-12T23:20:50.052Z")
        actual = decode({"~#t" => Util.date_time_to_millis(expected)})
        assert { Util.date_time_to_millis(actual) == Util.date_time_to_millis(expected) }
      end

      it 'decodes uuids from strings' do
        uuid = Transit::UUID.random
        decoded = decode({"~#u" => uuid.to_s})
        assert { decoded == uuid }
      end

      it 'decodes uuids from ints' do
        uuid = Transit::UUID.random
        decoded = decode({"~#u" => [uuid.most_significant_bits, uuid.least_significant_bits]})
        assert { decoded == uuid }
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

      it "decodes a 'typed array' of ints" do
        assert { decode({"~#ints" => [1,2,3,2,4]}) == IntsArray.new([1,2,3,2,4]) }
      end

      it 'decodes cmaps' do
        assert { decode({"~#cmap" => ["~:a", "b", "c", "~:d"]}) == {:a => "b", "c" => :d} }
      end

      it 'decodes nested cmaps' do
        cm1 = {"~#cmap" => ["~:a", "~:b"]}
        cm2 = {"~#cmap" => ["~:c", "~:d"]}
        cm3 = {"~#cmap" => [cm1, cm2]}
        assert { decode(cm3) == {{:a => :b} => {:c => :d}} }
      end

      it 'wraps unrecognized tags in a TaggedValue type' do
        map = {"~#unrecognized" => ["~:a",1]}
        assert { decode(map) == TaggedValue.new("~#unrecognized", [:a, 1]) }
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

      it 'decodes iso8601-formatted strings to GMT DateTime objects' do
        dt = DateTime.new(1985,4,12,23,20,50.052)
        assert { decode("~t1985-04-12T23:20:50.052Z") == dt }
        assert { decode("~t1985-04-12T23:20:50.052Z").zone == "+00:00" }
        assert { decode("~t1985-04-12T23:20:50.052Z").to_time.usec == 52000 }
      end

      it 'decodes millis to GMT DateTime objects' do
        dt = DateTime.new(1985,4,12,23,20,50.052).new_offset(0)
        millis_before = Transit::Util.date_time_to_millis(dt)
        decoded = decode({"~#t" => millis_before})
        millis_after = Transit::Util.date_time_to_millis(decoded)
        assert { millis_after == millis_before }
      end

      it 'decodes uuids from strings' do
        assert { decode("~ub54adc00-67f9-11d9-9669-0800200c9a66").is_a? UUID }
        assert { decode("~ub54adc00-67f9-11d9-9669-0800200c9a66") ==
          Transit::UUID.new("b54adc00-67f9-11d9-9669-0800200c9a66") }
      end

      it 'decodes uris' do
        assert { decode("~rprotocol://domain") == Addressable::URI.parse("protocol://domain") }
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
          decoder.register("r") {|u| "DECODED: #{u}"}
          assert { decoder.decode("~rhttp://foo.com") == "DECODED: http://foo.com" }
        end

        it 'supports override of default string decoders' do
          decoder = Decoder.new
          decoder.register("r", :string) {|u| "DECODED: #{u}"}
          assert { decoder.decode("~rhttp://foo.com") == "DECODED: http://foo.com" }
        end

        it 'supports override of default hash decoders' do
          my_uuid_class = Class.new(String)
          decoder = Decoder.new
          my_uuid = my_uuid_class.new(UUID.new.to_s)

          decoder.register("u") {|u| my_uuid_class.new(u)}
          assert { decoder.decode({"~#u" => my_uuid.to_s}) == my_uuid }
        end

        it 'supports override of the default default string encoder' do
          decoder = Decoder.new
          decoder.register(:default_string_decoder) {|s| raise "Unacceptable: #{s}"}
          assert { rescuing { decoder.decode("~Xabc") }.message =~ /Unacceptable/ }
        end

        it 'supports override of the default default hash encoder' do
          decoder = Decoder.new
          decoder.register(:default_hash_decoder) {|s| raise "Unacceptable: #{s}"}
          assert { rescuing { decoder.decode({"~#X" => :anything}) }.message =~ /Unacceptable/ }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          decoder = Decoder.new
          decoder.register("D") {|s| Date.parse(s)}
          assert { decoder.decode("~D2014-03-15") == Date.new(2014,3,15) }
        end

        it 'supports string-based extensions with :string key' do
          decoder = Decoder.new
          decoder.register("D", :string) {|s| Date.parse(s)}
          assert { decoder.decode("~D2014-03-15") == Date.new(2014,3,15) }
        end

        it 'raises when specifying :string w/ a tag length > 1' do
          decoder = Decoder.new
          assert { rescuing { decoder.register("DATE", :string) {|_|} }.message =~ /string decoder/ }
        end

        it 'supports hash based extensions' do
          decoder = Decoder.new
          decoder.register("Times2") {|d| d * 2}
          assert { decoder.decode({"~#Times2" => 44}) == 88 }
        end

        it 'supports hash based extensions with :hash key' do
          decoder = Decoder.new
          decoder.register("Times2", :hash) {|d| d * 2}
          assert { decoder.decode({"~#Times2" => 44}) == 88 }
        end

        it 'supports hash based extensions that return nil'  do
          decoder = Decoder.new
          decoder.register("Nil") {|_| nil}
          assert { decoder.decode({"~#Nil" => :anything }) == nil }
        end

        it 'supports hash based extensions that return false' do
          decoder = Decoder.new
          decoder.register("False") {|_| false}
          assert { decoder.decode({"~#False" => :anything }) == false }
        end

        it 'supports complex hash values' do
          decoder = Decoder.new
          decoder.register("person") {|p| Person.new(p[:first_name],p[:last_name],p[:birthdate])}
          decoder.register("D") {|s| Date.parse(s)}

          expected = [Person.new("Transit", "Ruby", Date.new(2014,1,2)),
                      Person.new("Transit", "Ruby", Date.new(2014,1,3))]
          actual   = decoder.decode([
                                     {"~#person"=>{"~:first_name" => "Transit","~:last_name" => "Ruby","~:birthdate" => "~D2014-01-02"}},
                                     {"^!"=>{"^\"" => "Transit","^#" => "Ruby","^$" => "~D2014-01-03"}}
                                    ])
          assert { actual == expected }
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

    describe "edge cases" do
      it "decodes escape characters (as Chars)" do
        expected = %w[` ~ ^ #].map {|c| Char.new(c)}
        assert { decode(["~c`","~c~","~c^","~c#"]) == expected }
      end
    end
  end
end
