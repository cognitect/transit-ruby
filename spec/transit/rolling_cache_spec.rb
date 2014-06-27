# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'

module Transit
  describe RollingCache do
    describe 'encoding' do
      it 'returns the value the first time it sees it' do
        assert { RollingCache.new.write('abcd', true) == 'abcd' }
      end

      it 'returns a key the 2nd thru n times it sees a value' do
        rc = RollingCache.new
        assert { rc.write('abcd', true) == 'abcd' }

        key = rc.write('abcd', true)
        assert { key == '^!' }

        100.times do
          assert { rc.write('abcd', true) == key }
        end
      end

      it 'keeps track of the number of values writed' do
        rc = RollingCache.new
        rc.write('abcd', true)
        rc.write('xxxx', true)
        rc.write('yyyy', true)
        assert {rc.size == 3}
      end

      it 'has a default CACHE_SIZE of 94' do
        assert { RollingCache::CACHE_SIZE == 94**2 }
      end

      it 'can handle CACHE_SIZE different values' do
        rc = RollingCache.new
        RollingCache::CACHE_SIZE.times do |i|
          assert { rc.write("value#{i}", true) == "value#{i}" }
        end

        assert { rc.size == RollingCache::CACHE_SIZE }
      end

      it 'resets after CACHE_SIZE different values' do
        rc = RollingCache.new
        (RollingCache::CACHE_SIZE+1).times do |i|
          assert{ rc.write("value#{i}", true) == "value#{i}" }
        end

        assert { rc.size == 1 }
      end

      it 'keeps the cache size capped at CACHE_SIZE' do
        sender = RollingCache.new
        receiver = RollingCache.new

        names = random_strings(3, 500)
        (RollingCache::CACHE_SIZE*5).times do |i|
          name = names.sample
          receiver.read(sender.write(name))
          assert { sender.size <= RollingCache::CACHE_SIZE }
          assert { receiver.size <= RollingCache::CACHE_SIZE }
        end
      end

      it 'does not cache small strings' do
        cache = RollingCache.new

        names = random_strings(3, 500)
        2000.times do |i|
          name = names.sample
          assert { cache.write(name) == name }
          assert { cache.size == 0 }
        end
      end
    end

    describe "decoding" do
      it 'returns the value, given a key that has a value in the cache' do
        rc = RollingCache.new
        rc.write 'abcd'
        key = rc.write 'abcd'
        assert { rc.read(key) == 'abcd' }
      end

      it 'returns the key, given a key that has no matching value in the cache' do
        rc = RollingCache.new
        assert { rc.read('abcd') == 'abcd' }
      end

      it 'always returns working keys' do
        sender = RollingCache.new
        receiver = RollingCache.new

        names = random_strings(200, 10)

        10000.times do |i|
          name = names.sample
          assert { receiver.read(sender.write(name)) == name }
        end
      end
    end
  end
end
