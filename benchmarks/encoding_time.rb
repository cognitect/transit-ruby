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

n = 10000

$date_time = DateTime.now
$time      = Time.now
$date      = Date.today

def header(s)
  puts s.sub(/^\$/,'')
  puts eval(s)
end

Benchmark.benchmark do |bm|
  header '$date_time.new_offset(0).strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do
        $date_time.new_offset(0).strftime("%FT%H:%M:%S.%LZ")
      end
    end
  end

  puts

  header '$date_time.to_time.utc.strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do;
        $date_time.to_time.utc.strftime(Transit::TIME_FORMAT)
      end
    end
  end

  puts

  header "$date_time.to_time.utc.iso8601(3)"
  3.times do
    bm.report do
      n.times do
        $date_time.to_time.utc.iso8601(3)
      end
    end
  end

  puts

  header '$time.getutc.strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do
        $time.getutc.strftime(Transit::TIME_FORMAT)
      end
    end
  end

  puts

  header '$time.to_datetime.new_offset(0).strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do
        $time.to_datetime.new_offset(0).strftime(Transit::TIME_FORMAT)
      end
    end
  end

  puts

  header '$date.to_datetime.strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do
        $date.to_datetime.strftime(Transit::TIME_FORMAT)
      end
    end
  end

  puts

  header '$date.to_time.strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do
        $date.to_time.strftime(Transit::TIME_FORMAT)
      end
    end
  end

  puts

  header 'Time.gm($date.year, $date.month, $date.day).iso8601(3)'
  3.times do
    bm.report do
      n.times do
        Time.gm($date.year, $date.month, $date.day).iso8601(3)
      end
    end
  end

  puts

  header 'Time.gm($date.year, $date.month, $date.day).strftime(Transit::TIME_FORMAT)'
  3.times do
    bm.report do
      n.times do
        Time.gm($date.year, $date.month, $date.day).strftime(Transit::TIME_FORMAT)
      end
    end
  end
end

__END__

$ ruby benchmarks/encoding_time.rb
date_time.new_offset(0).strftime(Transit::TIME_FORMAT)
2014-04-18T19:35:20.150Z
   0.020000   0.000000   0.020000 (  0.022102)
   0.020000   0.000000   0.020000 (  0.020739)
   0.030000   0.010000   0.040000 (  0.025088)

date_time.to_time.utc.strftime(Transit::TIME_FORMAT)
2014-04-18T19:35:20.150Z
   0.080000   0.000000   0.080000 (  0.081011)
   0.070000   0.000000   0.070000 (  0.079435)
   0.080000   0.000000   0.080000 (  0.079693)

date_time.to_time.utc.iso8601(3)
2014-04-18T19:35:20.150Z
   0.100000   0.000000   0.100000 (  0.095387)
   0.100000   0.000000   0.100000 (  0.099325)
   0.090000   0.000000   0.090000 (  0.097779)

time.getutc.strftime(Transit::TIME_FORMAT)
2014-04-18T19:35:20.150Z
   0.030000   0.000000   0.030000 (  0.022180)
   0.020000   0.000000   0.020000 (  0.023639)
   0.030000   0.000000   0.030000 (  0.027751)

time.to_datetime.new_offset(0).strftime(Transit::TIME_FORMAT)
2014-04-18T19:35:20.150Z
   0.040000   0.000000   0.040000 (  0.043754)
   0.040000   0.000000   0.040000 (  0.039013)
   0.040000   0.000000   0.040000 (  0.044270)

date.to_datetime.strftime(Transit::TIME_FORMAT)
2014-04-18T00:00:00.000Z
   0.020000   0.000000   0.020000 (  0.020463)
   0.020000   0.000000   0.020000 (  0.020716)
   0.030000   0.000000   0.030000 (  0.022477)

date.to_time.strftime(Transit::TIME_FORMAT)
2014-04-18T00:00:00.000Z
   0.090000   0.000000   0.090000 (  0.098463)
   0.090000   0.000000   0.090000 (  0.082547)
   0.080000   0.000000   0.080000 (  0.088301)

Time.gm($date.year, $date.month, $date.day).iso8601(3)
2014-04-18T00:00:00.000Z
   0.050000   0.000000   0.050000 (  0.050571)
   0.070000   0.000000   0.070000 (  0.063049)
   0.050000   0.000000   0.050000 (  0.049378)

Time.gm($date.year, $date.month, $date.day).strftime(Transit::TIME_FORMAT)
2014-04-18T00:00:00.000Z
   0.030000   0.000000   0.030000 (  0.037934)
   0.040000   0.000000   0.040000 (  0.038376)
   0.040000   0.000000   0.040000 (  0.037938)
