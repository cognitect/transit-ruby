# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'

module Transit
  describe TransitSymbol do
    it 'can be made from a symbol' do
      500.times do
        sym = random_symbol
        assert { TransitSymbol.new(sym).to_sym == sym }
      end
    end

    it 'can be made from a string' do
      500.times do
        str = random_string
        assert { TransitSymbol.new(str).to_sym == str.to_sym }
      end
    end

    it 'is equal to another rendition of itself' do
      500.times do
        sym = random_symbol
        assert { TransitSymbol.new(sym) == TransitSymbol.new(sym)}
      end
    end

    it 'behaves as a hash key' do
      keys = Set.new(Array.new(1000).map {|x| random_symbol})

      test_hash = {}
      keys.each_with_index {|k, i| test_hash[TransitSymbol.new(k)] = i}

      keys.each_with_index do |k, i|
        new_key = TransitSymbol.new(k)
        value = test_hash[new_key]
        assert { value == i }
      end
    end
  end

  describe Char do
    it 'raises when initialized w/ more than one char' do
      assert { rescuing { Char.new("foo") }.kind_of? ArgumentError }
    end
  end

  describe UUID do
    it 'round trips strings' do
      100.times do
        uuid = UUID.random
        s    = uuid.to_s
        assert { UUID.new(s)  == uuid }
      end
    end

    it 'round trips ints' do
      100.times do
        uuid = UUID.random
        msb, lsb = uuid.most_significant_bits, uuid.least_significant_bits
        assert { UUID.new(msb,lsb) == uuid }
        assert { UUID.new([msb,lsb]) == uuid }
      end
    end
  end
end
