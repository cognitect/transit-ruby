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

    it 'finds Transit::Unmarshaler::Json class', focus: true do
      expect { Transit::Unmarshaler::Json }.not_to raise_error
      binding.pry
    end

    it 'finds Transit::Unmarshaler::MessagePack class', focus: true do
      expect { Transit::Unmarshaler::MessagePack }.not_to raise_error
    end

    it 'reads without a block' do
      assert { read([1,2,3]) == [1,2,3] }
    end
  end
end
