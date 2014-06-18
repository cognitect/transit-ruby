# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  module DateTimeUtil
    def to_millis(v)
      case v
      when DateTime
        t = v.new_offset(0).to_time
      when Date
        t = Time.gm(v.year, v.month, v.day)
      when Time
        t = v.getutc
      else
        raise "Don't know how to get millis from #{t.inspect}"
      end
      (t.to_i * 1000) + (t.usec / 1000)
    end

    def from_millis(millis)
      t = Time.at(millis / 1000).utc
      DateTime.new(t.year, t.month, t.day, t.hour, t.min, t.sec + (millis % 1000 * 0.001))
    end

    module_function :to_millis, :from_millis
  end
end
