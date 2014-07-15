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
  describe Decoder do
    def decode(o)
      Decoder.new.decode(o)
    end

    describe "caching" do
      it "decodes cacheable map keys" do
        assert { decode([{"this" => "a"},{"^0" => "b"}]) == [{"this" => "a"},{"this" => "b"}] }
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
