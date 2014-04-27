require 'spec_helper'

module Transit
  describe DateTimeUtil do
    describe "time_[to|from]_millis" do
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

    describe "time_to_millis" do
      it "(at least sometimes) has non-zero millis" do
        a = 1.upto(20).map { sleep(0.0001); Transit::DateTimeUtil.to_millis(DateTime.now) % 1000 }
        assert { a.reduce(&:+) > 0 }
      end
    end

    describe "from_millis" do
      it "converts to utc" do
        t = DateTime.now
        m = Transit::DateTimeUtil.to_millis(t)
        f = Transit::DateTimeUtil.from_millis(m)
        assert { f.zone == '+00:00' }
      end
    end
  end
end
