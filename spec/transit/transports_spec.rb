require 'spec_helper'

module Transit
  describe Transports do
    shared_examples "round trips" do
      it 'can round trip a simple hash' do
        hash = {'a' => 1, 'b' => 2, 'name' => 'russ'}
        should_survive_roundtrip hash
      end

      it 'can round trip a hash containing a Clojure symbol' do
        should_survive_roundtrip({'key' => ClojureSymbol.new("foo")})
      end

      it 'can round trip a byte array' do
        should_survive_roundtrip ByteArray.new("abcdef\n\r\tghij")
      end

      it 'can round trip a string that begins with "~"' do
        should_survive_roundtrip "~this-string"
      end

      it 'can round trip a Time object' do
        should_survive_roundtrip Time.parse("1963-11-26T00:00:00.00Z")
      end

      it 'can round trip a URI object' do
        should_survive_roundtrip URI("http://foo.com")
        should_survive_roundtrip URI("datomic:dev://localhost:4334")
      end
    end

    describe "using json for transport" do
      before { stub_const "Transit::Transports::TRANSPORT", :json }
      include_examples "round trips"
    end

    describe "using msgpack for transport" do
      before { stub_const "Transit::Transport::TRANSPORT", :msgpack }
      include_examples "round trips"
    end
  end
end
