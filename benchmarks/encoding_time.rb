$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require 'transit'
require 'benchmark'

decoder = Transit::Decoder.new
special_decoder = Transit::Decoder.new
special_decoder.register("t") {|t| Transit::Util.time_from_millis(t.to_i)}

n = 10000

t = Time.now
m = Transit::Util.time_to_millis(t)
m_to_s = m.to_s
s = t.utc.iso8601(3)
c = Transit::RollingCache.new

def parse(rep)
  if rep =~ /Z$/
    Time.parse(rep).utc
  else
    Transit::Util.time_from_millis(rep.to_i).utc
  end
end

Benchmark.benchmark do |bm|
  puts "Time from #{s.inspect}"
  3.times do
    bm.report do
      n.times do
        Time.parse(s).utc
      end
    end
  end

  puts

  puts "Time from #{m_to_s.inspect}"
  3.times do
    bm.report do
      n.times do
        Transit::Util.time_from_millis(m_to_s.to_i).utc
      end
    end
  end

  puts

  puts "Time from #{m.inspect}"
  3.times do
    bm.report do
      n.times do
        Transit::Util.time_from_millis(m).utc
      end
    end
  end

  puts

  puts "decoder.decode(\"~t#{s}\")"
  3.times do
    bm.report do
      n.times do
        decoder.decode("~t#{s}", c)
      end
    end
  end

  puts

  puts "decoder.decode(\"~t#{m}\")"
  3.times do
    bm.report do
      n.times do
        special_decoder.decode("~t#{m}", c)
      end
    end
  end

  puts

  puts "decoder.decode({\"~#t\" => #{m}})"
  3.times do
    bm.report do
      n.times do
        decoder.decode({"~#t" => m}, c)
      end
    end
  end
end
