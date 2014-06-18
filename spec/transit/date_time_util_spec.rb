# Copyright (c) Cognitect, Inc.
# All rights reserved.

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
      it "supports DateTime" do
        assert { Transit::DateTimeUtil.to_millis(DateTime.new(2014,1,2,3,4,5.678r).new_offset(0)) == 1388631845678 }
      end

      it "supports Time" do
        assert { Transit::DateTimeUtil.to_millis(Time.new(2014,1,2,3,4,5.678r, "+00:00")) == 1388631845678 }
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
        assert { Transit::DateTimeUtil.from_millis(1388631845674) == DateTime.new(2014,1,2,3,4,5.674r).new_offset(0) }
        assert { Transit::DateTimeUtil.from_millis(1388631845675) == DateTime.new(2014,1,2,3,4,5.675r).new_offset(0) }
        assert { Transit::DateTimeUtil.from_millis(1388631845676) == DateTime.new(2014,1,2,3,4,5.676r).new_offset(0) }
      end
    end
  end
end
