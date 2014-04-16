$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require 'transit'
require 'benchmark'

decoder = Transit::Decoder.new
custom_decoder = Transit::Decoder.new
custom_decoder.register("t") {|t| Transit::Util.date_time_from_millis(t.to_i)}

n = 10000

t = Time.now
m = Transit::Util.date_time_to_millis(t)
m_to_s = m.to_s
s = t.utc.iso8601(3)

results = [Time.parse(s).utc,
           Transit::Util.date_time_from_millis(m),
           Transit::Util.date_time_from_millis(m_to_s.to_i),
           decoder.decode("~t#{s}"),
           decoder.decode({"~#t" => m}),
           custom_decoder.decode("~t#{m}")]

as_millis = results.map {|r| Transit::Util.date_time_to_millis(r)}

if Set.new(as_millis).length > 1
  warn "Not all methods returned the same values:"
  warn as_millis.to_s
end

Benchmark.benchmark do |bm|
  puts "Time.parse(#{s.inspect}).utc"
  3.times do
    bm.report do
      n.times do
        Time.parse(s).utc
      end
    end
  end

  puts
  puts "Transit::Util.date_time_from_millis(#{m.inspect})"
  3.times do
    bm.report do
      n.times do
        Transit::Util.date_time_from_millis(m)
      end
    end
  end

  puts
  puts "Transit::Util.date_time_from_millis(#{m_to_s.inspect}.to_i)"
  3.times do
    bm.report do
      n.times do
        Transit::Util.date_time_from_millis(m_to_s.to_i)
      end
    end
  end

  puts
  puts "decoder.decode(\"~t#{s}\")"
  3.times do
    bm.report do
      n.times do
        decoder.decode("~t#{s}")
      end
    end
  end

  puts
  puts "decoder.decode({\"~#t\" => #{m}})"
  3.times do
    bm.report do
      n.times do
        decoder.decode({"~#t" => m})
      end
    end
  end

  puts
  puts "custom_decoder.decode(\"~t#{m}\")"
  3.times do
    bm.report do
      n.times do
        custom_decoder.decode("~t#{m}")
      end
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
