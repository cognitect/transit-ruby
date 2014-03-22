require 'spec_helper'

module Transit
  describe Encoder do
    shared_examples "encoding" do
      [nil, true, false].each do |element|
        it "does not encode #{element.inspect}" do
          assert { Encoder.new.encode(element) == element }
        end
      end

      it 'does not encode ints' do
        assert { Encoder.new.encode(44) == 44 }
      end

      it 'encodes a BigDecimal' do
        assert { Encoder.new.encode(BigDecimal.new("123.456",3)) == "~f123.456" }
      end

      it 'encodes Ruby symbols as keywords' do
        assert {Encoder.new.encode(:abc) == "~:abc" }
      end

      it 'encodes ClojureSymbol objects as symbols' do
        assert { Encoder.new.encode(ClojureSymbol.new("abc")) == "~'abc" }
      end

      it 'does not encode (most) strings' do
        assert { Encoder.new.encode("hello") == "hello" }
      end

      it 'encodes a string that starts with "~"' do
        assert {Encoder.new.encode("~escape-me") == "~~escape-me"}
      end

      it 'does not encode floats' do
        assert { Encoder.new.encode(3.14) == 3.14 }
      end

      it 'encodes a set as an array in an encoded hash' do
        result = Encoder.new.encode(Set.new([1, 2, 3]))
        assert { result == { "~#s" => [1,2,3] } }
      end

      it 'recursively encodes the elements of a set' do
        now = Time.now
        uuid = UUID.new
        result = Encoder.new.encode(Set.new([:a, [now], {uuid => "~escaped"}]))
        assert { result ==
          { "~#s" =>
            ["~:a", [Encoder.new.encode(now)], {Encoder.new.encode(uuid) => "~~escaped"}] } }
      end

      it 'does not encode empty arrays' do
        assert { Encoder.new.encode([]) == [] }
      end

      it 'encodes the elements in an array' do
        now = Time.now
        uuid = UUID.new
        assert { Encoder.new.encode([1,now,uuid]) == [1,Encoder.new.encode(now),Encoder.new.encode(uuid)] }
      end

      it 'does not encode empty hashes' do
        assert { Encoder.new.encode({}) == {} }
      end

      it 'recursively encodes the keys and values in a hash' do
        now = Time.now
        assert { Encoder.new.encode({a: now}) == { Encoder.new.encode(:a) => Encoder.new.encode(now) } }
        assert {Encoder.new.encode({"a" => {b: now}}) ==
          {"a" => { Encoder.new.encode(:b) => Encoder.new.encode(now)}} }
      end
    end

    describe "encoding for json" do
      include_examples "encoding"

      it 'converts a Time instance to a hash with a specific key' do
        now = Time.now
        assert { Encoder.new.encode(now) == "~t#{now.strftime('%FT%H:%M:%S.%LZ')}" }
      end

      it 'converts a UUID instance to a json object with a single #uuid key' do
        uuid = UUID.new
        assert { Encoder.new.encode(uuid) == "~u#{uuid}" }
      end
    end

    describe "encoding for msgpack" do
      include_examples "encoding"

      it 'converts a Time instance to a hash with a specific key when asked' do
        now = Time.now
        encoder = Encoder.new(time: :hash)
        assert { encoder.encode(now) == {"~#t" => now.strftime("%FT%H:%M:%S.%LZ")} }
      end

      it 'converts a UUID instance to a hash with a single #uuid key with the proper option' do
        encoder = Encoder.new(uuid: :hash)
        encoded = encoder.encode(UUID.new)
        assert { encoded.keys.first == "~#u" }
        assert { encoded.size == 1 }
        assert { String === encoded.values.first }
      end
    end

    describe 'registration' do
      it 'requires a 1-arg lambda' do
        assert { rescuing { Encoder.new.register(Date) {|s,t|} }.
          message =~ /arity/ }
      end

      describe 'overrides' do
        it 'supports override of default string encoders' do
          encoder = Encoder.new
          encoder.register(Float) {|f| "~fFLOAT#{f}"}
          assert { encoder.encode(12.3) == "~fFLOAT12.3" }
        end

        it 'supports override of default hash encoders' do
          encoder = Encoder.new
          encoder.register(UUID) {|n| {"~#u" => n.to_s.reverse} }
          u = UUID.new
          assert { encoder.encode(u)["~#u"] == u.to_s.reverse }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          encoder = Encoder.new
          encoder.register(Date) {|d| "~D#{d}" }
          assert { encoder.encode(Date.parse("2014-03-15")) == "~D2014-03-15" }
        end

        it 'supports hash based extensions' do
          encoder = Encoder.new
          encoder.register(Date) {|d| {"~#D" => d.to_s}}
          assert { encoder.encode(Date.parse("2014-03-15")) == {"~#D" => "2014-03-15"} }
        end

        it 'supports hash based extensions that return nil'  do
          encoder = Encoder.new
          encoder.register(NilClass) {|_| {"~#N" => nil}}
          assert { encoder.encode(nil)["~#N"] == nil }
        end

        it 'supports hash based extensions that return false' do
          encoder = Encoder.new
          encoder.register(FalseClass) {|_| {"~#F" => false}}
          assert { encoder.encode(false)["~#F"] == false }
        end
      end
    end
  end
end
