require 'spec_helper'

module Transit
  describe Marshaler do
    let(:emitter)   { TransitEmitter.new }
    let(:marshaler) { Marshaler.new(emitter) }
    let(:cache)     { RollingCache.new }

    it 'marshals 1 at top' do
      marshaler.marshal_top(1, cache)
      assert { emitter.value == 1 }
    end

    it 'escapes a string' do
      marshaler.marshal_top("~this", cache)
      assert { emitter.value == "~~this" }
    end

    it 'marshals 1 in an array' do
      marshaler.marshal_top([1], cache)
      assert { emitter.value == [1] }
    end

    it 'marshals 1 in a nested array' do
      marshaler.marshal_top([[1]], cache)
      assert { emitter.value == [[1]] }
    end

    it 'marshals a map' do
      marshaler.marshal_top({"a" => 1}, cache)
      assert { emitter.value == {"a" => 1} }
    end

    it 'marshals a nested map' do
      marshaler.marshal_top({"a" => {"b" => 1}}, cache)
      assert { emitter.value == {"a" => {"b" => 1}} }
    end

    it 'marshals a big mess' do
      input   = {"~a" => [1, {:b => [2,3]}, 4]}
      output  = {"~~a" => [1, {"~:b" => [2,3]}, 4]}
      marshaler.marshal_top(input, cache)
      assert { emitter.value == output }
    end

    it 'marshals a top-level scalar in a map when requested' do
      marshaler =  Marshaler.new(emitter, :quote_scalars => true)
      marshaler.marshal_top(1, cache)
      assert { emitter.value == {"~#'"=>1} }
    end
  end
end
