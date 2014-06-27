# -*- coding: utf-8 -*-
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

    it "provides namespace" do
      assert { TransitSymbol.new("foo/bar").namespace == "foo" }
      assert { TransitSymbol.new("foo").namespace == nil }
    end

    it "provides name" do
      assert { TransitSymbol.new("foo").name == "foo" }
      assert { TransitSymbol.new("foo/bar").name == "bar" }
    end

    it "special cases '/'" do
      assert { TransitSymbol.new("/").name == "/" }
      assert { TransitSymbol.new("/").namespace == nil }
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

  describe Link, focus: true do
    let(:href) { "http://example.org/search" }
    let(:rel) { "search" }
    let(:prompt) { "Enter search string" }
    let(:name) { "search" }

    it 'can be made from some given arugments' do
      link = Link.new(href, rel)
      assert { link.href == href }
      assert { link.rel == rel }
      assert { link.prompt == nil }
      assert { link.name == nil }
      assert { link.render == nil }
    end

    it 'can be made from all 5 given correct arguments' do
      link = Link.new(href, rel, prompt, name, "Image")
      assert { link.href == href }
      assert { link.rel == rel }
      assert { link.prompt == prompt }
      assert { link.name == name }
      assert { link.render == "image" }
    end

    it 'raises exception if href and rel are not given' do
      expect { Link.new }.to raise_error
    end

    it 'raises exception if render is not correct value' do
      expect { Link.new(href, rel, nil, nil, "document") }.to raise_error(ArgumentError)
    end

    it 'raises exception when map is modified later' do
      link = Link.new(href, rel)
      map = link.instance_variable_get("@m")
      expect { map["render"] = "link" }.to raise_error
    end
  end
end
