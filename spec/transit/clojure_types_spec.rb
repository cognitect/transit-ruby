require 'spec_helper'

module Transit
  describe ClojureSymbol do
    it 'can be made from a symbol' do
      500.times do
        sym = random_symbol
        assert { ClojureSymbol.new(sym).to_sym == sym }
      end
    end

    it 'can be made from a string' do
      500.times do
        str = random_string
        assert { ClojureSymbol.new(str).to_sym == str.to_sym }
      end
    end

    it 'is equal to another rendition of itself' do
      500.times do
        sym = random_symbol
        assert { ClojureSymbol.new(sym) == ClojureSymbol.new(sym)}
      end
    end

    it 'behaves as a hash key' do
      keys = Set.new(Array.new(1000).map {|x| random_symbol})

      test_hash = {}
      keys.each_with_index {|k, i| test_hash[ClojureSymbol.new(k)] = i}

      keys.each_with_index do |k, i|
        new_key = ClojureSymbol.new(k)
        value = test_hash[new_key]
        assert { value == i }
      end
    end
  end
end
