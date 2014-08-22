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

module Transit
  # @api private
  module DateTimeUtil
    def to_millis(v)
      case v
      when DateTime
        t = v.new_offset(0).to_time
      when Date
        t = Time.gm(v.year, v.month, v.day)
      when Time
        t = v
      else
        raise "Don't know how to get millis from #{t.inspect}"
      end
      (t.to_i * 1000) + (t.usec / 1000.0).round
    end

    def from_millis(millis)
      t = Time.at(millis / 1000).utc
      DateTime.new(t.year, t.month, t.day, t.hour, t.min, t.sec + (millis % 1000 * 0.001))
    end

    module_function :to_millis, :from_millis
  end
end
