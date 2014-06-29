# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'

module Transit
  describe Decoder do
    def decode(o)
      Decoder.new.decode(o)
    end

    describe "caching" do
      it "decodes cacheable map keys" do
        assert { decode([{"this" => "a"},{"^!" => "b"}]) == [{"this" => "a"},{"this" => "b"}] }
      end

      it "does not cache non-map-keys" do
        assert { decode([{"a" => "~^!"},{"b" => "~^?"}]) == [{"a" => "^!"},{"b" => "^?"}] }
      end
    end

    describe "formats" do
      describe "JSON_M" do
        it "converts an array starting with '^ ' to a map" do
          assert { decode(["^ ", :a, :b, :c, :d]) == {:a => :b, :c => :d} }
        end
      end
    end

    describe "unrecognized input" do
      it "decodes an unrecognized string to a TaggedValue" do
        assert { decode("~Unrecognized") == TaggedValue.new("U", "nrecognized") }
      end
    end

    describe "ints" do
      it "decodes n as an Integer" do
        1.upto(64).each do |pow|
          assert { decode("~n#{2**pow}").kind_of? Integer }
        end
      end
      it "decodes i as an Integer" do
        1.upto(63).each do |pow|
          assert { decode("~i#{2**pow - 1}").kind_of? Integer }
        end
      end
    end
  end
end
