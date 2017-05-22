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

$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require 'transit'
require 'benchmark'

decoder = Transit::Decoder.new

custom_t = Class.new do
  def from_rep(t)
    Transit::DateTimeUtil.from_millis(t.to_i)
  end
end

custom_decoder = Transit::Decoder.new(handlers: {"t" => custom_t.new})

n = 10000

t = Time.now
m = Transit::DateTimeUtil.to_millis(t)
m_to_s = m.to_s
s = t.utc.iso8601

results = [Time.parse(s).utc,
           Transit::DateTimeUtil.from_millis(m),
           Transit::DateTimeUtil.from_millis(m_to_s.to_i),
           decoder.decode("~t#{s}"),
           decoder.decode({"~#m" => m}),
           custom_decoder.decode("~t#{m}")]

as_millis = results.map {|r| Transit::DateTimeUtil.to_millis(r)}

if Set.new(as_millis).length > 1
  warn "Not all methods returned the same values:"
  warn as_millis.to_s
end

puts
puts "Time.parse            => (Time.parse(#{s.inspect}).utc)"
puts "from_millis(int)      => Transit::DateTimeUtil.from_millis(#{m.inspect})"
puts "from_millis(str.to_i) => Transit::DateTimeUtil.from_millis(#{m_to_s.inspect}.to_i)"
puts "decode ~t             => decoder.decode(\"~t#{s}\")"
puts "decode ~#m            => decoder.decode({\"~#m\" => #{m}})"
puts "custom_decoder        => custom_decoder.decode(\"~t#{m}\"})"
puts

Benchmark.bmbm do |bm|
  bm.report "Time.parse" do
    n.times do
      Time.parse(s).utc
    end
  end

  bm.report "from_millis(int)" do
    n.times do
      Transit::DateTimeUtil.from_millis(m)
    end
  end

  bm.report "from_millis(str.to_i)" do
    n.times do
      Transit::DateTimeUtil.from_millis(m_to_s.to_i)
    end
  end

  bm.report "decode ~t" do
    n.times do
      decoder.decode("~t#{s}")
    end
  end

  bm.report "decode ~#m" do
    n.times do
      decoder.decode({"~#m" => m})
    end
  end

  bm.report "custom_decoder" do
    n.times do
      custom_decoder.decode("~t#{m}")
    end
  end
end

__END__

$ ruby benchmarks/decoding_time.rb
Not all methods returned the same values:
[1397450386660, 1397450386661, 1397450386661, 1397450386660, 1397450386661, 1397450386661]

# This ^^ shows that Time.new.iso8601(3) is truncating millis instead of rounding them.

Time.parse("2014-04-14T04:39:46.660Z").utc
   0.270000   0.000000   0.270000 (  0.265990)
   0.260000   0.000000   0.260000 (  0.261357)
   0.260000   0.000000   0.260000 (  0.263597)

Transit::Util.date_time_from_millis(1397450386661)
   0.040000   0.000000   0.040000 (  0.041289)
   0.040000   0.000000   0.040000 (  0.043084)
   0.050000   0.000000   0.050000 (  0.043169)

Transit::Util.date_time_from_millis("1397450386661".to_i)
   0.040000   0.000000   0.040000 (  0.048342)
   0.050000   0.000000   0.050000 (  0.047006)
   0.050000   0.010000   0.060000 (  0.046771)

decoder.decode("~t2014-04-14T04:39:46.660Z")
   0.310000   0.000000   0.310000 (  0.311126)
   0.310000   0.000000   0.310000 (  0.312943)
   0.320000   0.000000   0.320000 (  0.317080)

decoder.decode({"~#t" => 1397450386661})
   0.080000   0.000000   0.080000 (  0.081899)
   0.070000   0.000000   0.070000 (  0.077323)
   0.080000   0.000000   0.080000 (  0.079400)

custom_decoder.decode("~t1397450386661")
   0.080000   0.000000   0.080000 (  0.074236)
   0.080000   0.000000   0.080000 (  0.080308)
   0.070000   0.000000   0.070000 (  0.075567)
