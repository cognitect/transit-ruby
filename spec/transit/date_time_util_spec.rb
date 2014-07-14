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
  describe DateTimeUtil do
    describe "[to|from]_millis" do
      it "round trips properly" do
        100.times do
          n = DateTime.now
          a = Transit::DateTimeUtil.to_millis(n)
          b = Transit::DateTimeUtil.from_millis(a)
          c = Transit::DateTimeUtil.to_millis(b)
          d = Transit::DateTimeUtil.from_millis(c)
          assert { a == c }
          assert { b == d }
          sleep(0.0001)
        end
      end
    end

    describe "to_millis" do
      let(:time) { Time.at(1388631845) + 0.678 }

      it "supports DateTime" do
        assert { Transit::DateTimeUtil.to_millis(time.to_datetime) == 1388631845678 }
      end

      it "supports Time" do
        assert { Transit::DateTimeUtil.to_millis(time) == 1388631845678 }
      end

      it "supports Date" do
        assert { Transit::DateTimeUtil.to_millis(Date.new(2014,1,2)) == 1388620800000 }
      end
    end

    describe "from_millis" do
      it "converts to utc" do
        t = DateTime.now
        m = Transit::DateTimeUtil.to_millis(t)
        f = Transit::DateTimeUtil.from_millis(m)
        assert { f.zone == '+00:00' }
      end

      it "handles millis properly" do
        assert { Transit::DateTimeUtil.from_millis(1388631845674) == DateTime.new(2014,1,2,3,4,5.674).new_offset(0) }
        assert { Transit::DateTimeUtil.from_millis(1388631845675) == DateTime.new(2014,1,2,3,4,5.675).new_offset(0) }
        assert { Transit::DateTimeUtil.from_millis(1388631845676) == DateTime.new(2014,1,2,3,4,5.676).new_offset(0) }
      end
    end
  end
end
