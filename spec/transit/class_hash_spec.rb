require 'spec_helper'

module Transit
  describe ClassHash do
    it 'finds explicit values like a hash' do
      cl = ClassHash.new
      cl[String] = 1
      cl[Symbol] = 2
      assert {cl[String] == 1}
      assert {cl[Symbol] == 2}
    end

    it 'returns the value for the first ancestor class it finds' do
      grandparent = Class.new
      parent      = Class.new(grandparent)
      child       = Class.new(parent)

      cl = ClassHash.new
      cl[grandparent] = :grandparent
      assert {cl[grandparent] == :grandparent}
      assert {cl[parent]      == :grandparent}
      assert {cl[child]       == :grandparent}
    end

    it 'returns the value for the first ancestor module it finds' do
      grandparent = Module.new
      parent      = Class.new { include grandparent }
      child       = Class.new(parent)

      cl = ClassHash.new
      cl[grandparent] = :grandparent
      assert {cl[grandparent] == :grandparent}
      assert {cl[parent]      == :grandparent}
      assert {cl[child]       == :grandparent}
    end

    it 'returns nil when no value is found' do
      cl = ClassHash.new
      assert {cl[String] == nil}
    end

    it 'returns an explicit value for Object when no value is found' do
      cl = ClassHash.new
      cl[Object] = :object
      assert {cl[String] == :object}
    end
  end
end
