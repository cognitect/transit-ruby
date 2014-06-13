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
  end
end
