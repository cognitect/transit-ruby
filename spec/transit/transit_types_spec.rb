# -*- coding: utf-8 -*-
# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

  describe Link do
    let(:href) { Addressable::URI.parse("http://example.org/search") }
    let(:string_href) { "http://example.org/search" }
    let(:rel) { "search" }
    let(:prompt) { "Enter search string" }
    let(:name) { "this is my name" }

    it 'can be made from some given arugments' do
      link = Link.new(href, rel)
      assert { link.href == href }
      assert { link.rel == rel }
      assert { link.prompt == nil }
      assert { link.name == nil }
      assert { link.render == nil }
    end

    it 'can be made from all 5 given correct arguments' do
      link = Link.new(href, rel, name, "Image", prompt)
      assert { link.href == href }
      assert { link.rel == rel }
      assert { link.name == name }
      assert { link.render == "image" }
      assert { link.prompt == prompt }
    end

    it 'can be made with uri in string' do
      link = Link.new(string_href, rel)
      assert { link.href == Addressable::URI.parse(string_href) }
    end

    it 'raises exception if href and rel are not given' do
      assert { rescuing { Link.new }.is_a? ArgumentError }
      assert { rescuing { Link.new("foo") }.is_a? ArgumentError }
    end

    it 'raises exception if render is not a valid value (link|image)' do
      assert { rescuing { Link.new(href, rel, nil, "document") }.is_a? ArgumentError }
    end

    it 'leaves the input map alone' do
      input = {"href" => "http://example.com", "rel" => "???", "render" => "LINK"}
      Link.new(input)
      assert { input["href"] == "http://example.com" }
      assert { input["render"] == "LINK" }
    end

    it 'produces a frozen map' do
      assert { Link.new("/path", "the-rel").to_h.frozen? }
    end
  end

  describe ByteArray do
    it 'uses the default_external encoding for to_s' do
      src = ByteArray.new("foo".force_encoding("ascii")).to_base64
      target = ByteArray.from_base64(src)
      assert { target.to_s.encoding == Encoding.default_external }
    end
  end
end
