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
  end
end
