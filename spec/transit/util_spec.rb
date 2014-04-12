require 'spec_helper'

module Transit
  describe Util do
    describe "time_[to|from]_millis" do
      it "round trips properly" do
        20.times do
          a = Transit::Util.time_to_millis(Time.now)
          b = Transit::Util.time_from_millis(a)
          c = Transit::Util.time_to_millis(b)
          d = Transit::Util.time_from_millis(c)
          assert { a % 1000 == c % 1000 }
          assert { b == d }
          sleep(0.0001)
        end
      end

      it "(at least sometimes) has non-zero millis" do
        a = 1.upto(20).map { sleep(0.0001); Transit::Util.time_to_millis(Time.now) % 1000 }
        assert { a.reduce(&:+) > 0 }
      end
    end
  end
end
