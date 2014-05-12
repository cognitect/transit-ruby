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
  end
end
