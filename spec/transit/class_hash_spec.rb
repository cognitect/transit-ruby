require 'spec_helper'

module Transit
  describe ClassHash do

    it 'finds explicit values like a hash' do
      cl = ClassHash.new
      cl[String] = 1
      cl[Symbol] = 2
      assert {cl[String] == 1}
      assert {cl[Symbol] == 2}
      assert {cl[Object] == nil}
    end

    it 'crawls up the inheritance tree looking for values' do
      cl = ClassHash.new
      cl[Integer] = :integer
      cl[Numeric] = :numeric
      cl[Object] = :object
      assert {cl[Fixnum] == :integer}
      assert {cl[Float] == :numeric}
      assert {cl[String] == :object}
    end

    it 'returns nil for classes that it knows noting about' do
      cl = ClassHash.new
      cl[Object] = :object
      assert {cl[BasicObject] == nil}
    end
  end
end
