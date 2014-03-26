require 'spec_helper'

module Transit
=begin
  describe Decoder do
    [nil, true, false].each do |element|
      it "decodes #{element.inspect} to itself" do
        assert { Decoder.new.decode(element) == element }
      end
    end

    it 'decodes an int to itself' do
      assert { Decoder.new.decode(1) == 1 }
    end

    it 'decodes a BigDecimal' do
      assert { Decoder.new.decode("~f123.456") == BigDecimal.new("123.456") }
    end

    it 'decodes a one-pair hash with simple values' do
      assert { Decoder.new.decode({a: 1}) == {a: 1} }
    end

    it 'decodes an ordinary hash with an encoded key' do
      assert { Decoder.new.decode({'~~escaped' => 37}) == {'~escaped' => 37} }
      assert { Decoder.new.decode({'~~escaped' => 37, a: 42}) == {'~escaped' => 37, a: 42} }
    end

    it 'decodes an ordinary hash with an encoded value' do
      assert { Decoder.new.decode({a: '~~escaped'}) == {a: '~escaped'} }
      assert { Decoder.new.decode({a: '~~escaped', b: 42}) == {a: '~escaped', b: 42} }
    end

    it 'decodes strings' do
      assert { Decoder.new.decode("foo") == "foo" }
    end

    it 'decodes an array of simple values' do
      assert { Decoder.new.decode([1,2,3,2,4]) == [1,2,3,2,4] }
    end

    describe "encoded hashes" do
      it 'decodes sets' do
        assert { Decoder.new.decode({"~#s" => [1,2,3,2,4]}) == Set.new([1,2,3,4]) }
      end

      it 'decodes lists' do
        assert { Decoder.new.decode({"~#(" => [1,2,3,2,4]}) == [1,2,3,2,4] }
      end
    end

    describe "tagged strings" do
      it 'decodes keywords to Ruby symbols' do
        assert { Decoder.new.decode("~:foo") == :foo }
      end

      it 'unescapes escaped strings' do
        assert { Decoder.new.decode("~~foo") == "~foo" }
      end

      it 'decodes ClojureSymbol into the Ruby version of Clojure symbols' do
        assert { Decoder.new.decode("~'foo") == ClojureSymbol.new("foo") }
      end

      it 'decodes base64 strings into ByteArray' do
        assert { Decoder.new.decode("~bYWJj\n").is_a? ByteArray }
        assert { Decoder.new.decode("~bYWJj\n").to_s ==
          Base64.decode64("YWJj\n") }
      end

      it 'decodes instants to Time objects' do
        assert { Decoder.new.decode("~t1985-04-12T23:20:50.52Z") ==
          Time.parse("1985-04-12T23:20:50.52Z") }

        assert { Decoder.new.decode({"~#t" => "1985-04-12T23:20:50.52Z"}) ==
          Time.parse("1985-04-12T23:20:50.52Z") }
      end

      it 'decodes uuids' do
        assert { Decoder.new.decode("~ub54adc00-67f9-11d9-9669-0800200c9a66").is_a? UUID }
        assert { Decoder.new.decode("~ub54adc00-67f9-11d9-9669-0800200c9a66") ==
          "b54adc00-67f9-11d9-9669-0800200c9a66" }
      end

      it 'decodes uris' do
        assert { Decoder.new.decode("~rprotocol://domain") == URI("protocol://domain") }
      end

      it 'decodes chars' do
        assert {Decoder.new.decode("~ca") == "a"}
      end
    end

    describe 'nested data' do
      it 'decodes an array of tagged strings' do
        [["~:kw",      :kw],
         ["~'cs",      ClojureSymbol.new("cs")],
         ["~f123.456", 123.456],
         ["~d3.14158", 3.14158]].map do |encoded, decoded|
          assert { Decoder.new.decode(encoded) == decoded }
        end
      end

      it 'decodes nested hashes' do
        assert { Decoder.new.decode({a: 1, b: 2, c: {d: 3}}) == {a: 1, b: 2, c: {d: 3}} }
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
          decoder.register("~r") {|s| s[2..-1]}
          assert { decoder.decode("~rhttp://foo.com") == "http://foo.com" }
        end

        it 'supports override of default hash decoders' do
          my_uuid_class = Class.new(String)
          decoder = Decoder.new
          my_uuid = my_uuid_class.new(UUID.new.to_s)

          decoder.register("~#u") {|h| my_uuid_class.new(h.values.first)}
          assert { decoder.decode({"~#u" => my_uuid.to_s}) == my_uuid }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          decoder = Decoder.new
          decoder.register("~D") {|s| Date.parse(s[2..-1])}
          assert { decoder.decode("~D2014-03-15") == Date.new(2014,3,15) }
        end

        it 'supports hash based extensions' do
          decoder = Decoder.new
          decoder.register("~#Xdouble") {|h| h.values.first * 2}
          assert { decoder.decode({"~#Xdouble" => 44}) == 88 }
        end

        it 'supports hash based extensions that return nil'  do
          decoder = Decoder.new
          decoder.register("~#Xmynil") {|_| nil}
          assert { decoder.decode({"~#Xmynil" => :anything }) == nil }
        end

        it 'supports hash based extensions that return false' do
          decoder = Decoder.new
          decoder.register("~#Xmyfalse") {|_| false}
          assert { decoder.decode({"~#Xmyfalse" => :anything }) == false }
        end
      end
    end
  end
=end
end
