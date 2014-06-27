# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'

module Transit
  describe Transit::Symbol do
    it 'can be made from a symbol' do
      500.times do
        sym = random_symbol
        assert { Transit::Symbol.new(sym).to_sym == sym }
      end
    end

    it 'can be made from a string' do
      500.times do
        str = random_string
        assert { Transit::Symbol.new(str).to_sym == str.to_sym }
      end
    end

    it 'is equal to another rendition of itself' do
      500.times do
        sym = random_symbol
        assert { Transit::Symbol.new(sym) == Transit::Symbol.new(sym)}
      end
    end

    it 'behaves as a hash key' do
      keys = Set.new(Array.new(1000).map {|x| random_symbol})

      test_hash = {}
      keys.each_with_index {|k, i| test_hash[Transit::Symbol.new(k)] = i}

      keys.each_with_index do |k, i|
        new_key = Transit::Symbol.new(k)
        value = test_hash[new_key]
        assert { value == i }
      end
    end

    it "provides namespace" do
      assert { Transit::Symbol.new("foo/bar").namespace == "foo" }
      assert { Transit::Symbol.new("foo").namespace == nil }
    end

    it "provides name" do
      assert { Transit::Symbol.new("foo").name == "foo" }
      assert { Transit::Symbol.new("foo/bar").name == "bar" }
    end

    it "special cases '/'" do
      assert { Transit::Symbol.new("/").name == "/" }
      assert { Transit::Symbol.new("/").namespace == nil }
    end
  end

  describe Char do
    it 'raises when initialized w/ more than one char' do
      assert { rescuing { Char.new("foo") }.kind_of? ArgumentError }
    end
  end

  describe UUID do
    it 'round trips strings' do
      10.times do
        uuid = UUID.random
        assert { UUID.new(uuid.to_s) == uuid }
      end
    end

    it 'round trips ints' do
      10.times do
        uuid = UUID.random
        assert { UUID.new(uuid.most_significant_bits, uuid.least_significant_bits) == uuid }
      end
    end
  end
end
