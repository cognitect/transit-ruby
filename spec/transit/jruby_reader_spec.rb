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
  describe Reader, :if => jruby? do
    def read(value, &block)
      reader = Reader.new(:json, StringIO.new(value.to_json, 'r+'))
      reader.read &block
    end

    it 'finds Transit::Unmarshaler::Json class' do
      expect { Transit::Unmarshaler::Json }.not_to raise_error
    end

    it 'finds Transit::Unmarshaler::MessagePack class' do
      expect { Transit::Unmarshaler::MessagePack }.not_to raise_error
    end

    it 'reads without a block' do
      assert { read([1,2,3]) == [1,2,3] }
    end

    it 'reads with a block' do
      result = nil
      read([1,2,3]) {|v| result = v}
      assert { result == [1,2,3] }
    end

    it 'supports hash based extensions that return false' do
      io = StringIO.new({"~#False" => :anything}.to_json)
      reader = Reader.new(:json, io, :handlers => {"False" => Class.new { def from_rep(_) false end}.new})
      assert { reader.read == false }
    end
  end
end
