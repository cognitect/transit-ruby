require 'spec_helper'

module Transit
  describe Marshaler do
    let(:emitter)   { TransitEmitter.new }
    let(:marshaler) { Marshaler.new(emitter) }

    it 'marshals 1 at top' do
      marshaler.marshal_top(1)
      assert { emitter.value == 1 }
    end

    it 'escapes a string' do
      marshaler.marshal_top("~this")
      assert { emitter.value == "~~this" }
    end

    it 'marshals 1 in an array' do
      marshaler.marshal_top([1])
      assert { emitter.value == [1] }
    end

    it 'marshals 1 in a nested array' do
      marshaler.marshal_top([[1]])
      assert { emitter.value == [[1]] }
    end

    it 'marshals a map' do
      marshaler.marshal_top({"a" => 1})
      assert { emitter.value == {"a" => 1} }
    end

    it 'marshals a nested map' do
      marshaler.marshal_top({"a" => {"b" => 1}})
      assert { emitter.value == {"a" => {"b" => 1}} }
    end

    it 'marshals a big mess' do
      input   = {"~a" => [1, {:b => [2,3]}, 4]}
      output  = {"~~a" => [1, {"~:b" => [2,3]}, 4]}
      marshaler.marshal_top(input)
      assert { emitter.value == output }
    end

    it 'marshals a top-level scalar in a map when requested' do
      marshaler =  Marshaler.new(emitter, :quote_scalars => true)
      marshaler.marshal_top(1)
      assert { emitter.value == {"~#'"=>1} }
    end

    it 'marshals time as a string for json' do
      t = Time.now
      emitter = TransitEmitter.new(true)
      marshaler =  Marshaler.new(emitter, :quote_scalars => false, :prefer_strings => true)
      marshaler.marshal_top(t)
      assert { emitter.value == "~t#{t.utc.iso8601(3)}" }
    end

    it 'marshals time as a map for msgpack' do
      t = Time.now
      emitter = TransitEmitter.new(false)
      marshaler =  Marshaler.new(emitter, :quote_scalars => false, :prefer_strings => false)
      marshaler.marshal_top(t)
      assert { emitter.value == {"~#t" => Util.time_to_millis(t)} }
    end
  end
end
