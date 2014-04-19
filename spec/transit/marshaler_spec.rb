require 'spec_helper'

module Transit
  describe Marshaler do
    let(:marshaler) { TransitMarshaler.new }

    it 'marshals 1 at top' do
      marshaler.marshal_top(1)
      assert { marshaler.value == 1 }
    end

    it 'escapes a string' do
      marshaler.marshal_top("~this")
      assert { marshaler.value == "~~this" }
    end

    it 'marshals 1 in an array' do
      marshaler.marshal_top([1])
      assert { marshaler.value == [1] }
    end

    it 'marshals 1 in a nested array' do
      marshaler.marshal_top([[1]])
      assert { marshaler.value == [[1]] }
    end

    it 'marshals a map' do
      marshaler.marshal_top({"a" => 1})
      assert { marshaler.value == {"a" => 1} }
    end

    it 'marshals a nested map' do
      marshaler.marshal_top({"a" => {"b" => 1}})
      assert { marshaler.value == {"a" => {"b" => 1}} }
    end

    it 'marshals a big mess' do
      input   = {"~a" => [1, {:b => [2,3]}, 4]}
      output  = {"~~a" => [1, {"~:b" => [2,3]}, 4]}
      marshaler.marshal_top(input)
      assert { marshaler.value == output }
    end

    it 'marshals a top-level scalar in a map when requested' do
      marshaler =  TransitMarshaler.new(:quote_scalars => true)
      marshaler.marshal_top(1)
      assert { marshaler.value == {"~#'"=>1} }
    end

    it 'marshals a ` encoded string without the `' do
      marshaler =  TransitMarshaler.new(:quote_scalars => false)
      marshaler.marshal_top("`~xfoo")
      assert { marshaler.value == "~xfoo" }
    end

    describe "json-specific rules" do
      it 'marshals Time as a string' do
        t = Time.new(2014,1,2,3,4,5.12345,"-05:00")
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(t)
        assert { marshaler.value == "~t2014-01-02T08:04:05.123Z" }
      end

      it 'marshals DateTime as a string' do
        dt = DateTime.new(2014,1,2,3,4,5.1235,"-5")
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(dt)
        assert { marshaler.value == "~t2014-01-02T08:04:05.123Z" }
      end

      it 'marshals a Date as a string' do
        t = Date.new(2014,1,2)
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(t)
        assert { marshaler.value == "~t2014-01-02T00:00:00.000Z" }
      end

      it 'marshals 2**53 as an int' do
        marshaler = TransitMarshaler.new(:max_int => JsonMarshaler::JSON_MAX_INT)
        marshaler.marshal_top(2**53)
        assert { marshaler.value == 2**53 }
      end

      it 'marshals 2**53 + 1 as an encoded string' do
        marshaler = TransitMarshaler.new(:max_int => JsonMarshaler::JSON_MAX_INT)
        marshaler.marshal_top(2**53 + 1)
        assert { marshaler.value == "~i#{2**53+1}" }
      end

      it 'marshals -2**53 as an int' do
        marshaler = TransitMarshaler.new(:min_int => JsonMarshaler::JSON_MIN_INT)
        marshaler.marshal_top(-2**53)
        assert { marshaler.value == -2**53 }
      end

      it 'marshals -(2**53 + 1) as an encoded string' do
        marshaler = TransitMarshaler.new(:min_int => JsonMarshaler::JSON_MIN_INT)
        marshaler.marshal_top(-(2**53 + 1))
        assert { marshaler.value == "~i-#{2**53+1}" }
      end

      it 'marshals a UUID as an encoded string' do
        uuid = UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7")
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => true)
        marshaler.marshal_top(uuid)
        assert { marshaler.value == "~udda5a83f-8f9d-4194-ae88-5745c8ca94a7" }
      end
    end

    describe "msgpack-specific rules" do
      it 'marshals Time as a map' do
        t = Time.now
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(t)
        assert { marshaler.value == {"~#t" => Util.date_time_to_millis(t)} }
      end

      it 'marshals DateTime as a map' do
        dt = DateTime.now
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(dt)
        assert { marshaler.value == {"~#t" => Util.date_time_to_millis(dt)} }
      end

      it 'marshals a Date as a map' do
        d = Date.new(2014,1,2)
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(d)
        assert { marshaler.value == {"~#t" => Util.date_time_to_millis(d) } }
      end

      it 'marshals 2**64 - 1 as an int' do
        marshaler = TransitMarshaler.new(:max_int => MessagePackMarshaler::MSGPACK_MAX_INT)
        marshaler.marshal_top(2**64-1)
        assert { marshaler.value == 2**64-1 }
      end

      it 'marshals 2**64 as an encoded string' do
        marshaler = TransitMarshaler.new(:max_int => MessagePackMarshaler::MSGPACK_MAX_INT)
        marshaler.marshal_top(2**64)
        assert { marshaler.value == "~i#{2**64}" }
      end

      it 'marshals -2**63 as an int' do
        marshaler = TransitMarshaler.new(:min_int => MessagePackMarshaler::MSGPACK_MIN_INT)
        marshaler.marshal_top(-2**63)
        assert { marshaler.value == -2**63 }
      end

      it 'marshals -(2**63 + 1) as an encoded string' do
        marshaler = TransitMarshaler.new(:min_int => MessagePackMarshaler::MSGPACK_MIN_INT)
        marshaler.marshal_top(-(2**63 + 1))
        assert { marshaler.value == "~i-#{2**63+1}" }
      end

      it 'marshals a UUID as a string in an encoded hash' do
        msb, lsb = 6353693437827696322, 11547645107031845111
        uuid = UUID.new(msb,lsb)
        marshaler =  TransitMarshaler.new(:quote_scalars => false, :prefer_strings => false)
        marshaler.marshal_top(uuid)
        assert { marshaler.value == {"~#u" => [msb,lsb].map{|i| "~i#{i}"}} }
      end
    end
  end
end
