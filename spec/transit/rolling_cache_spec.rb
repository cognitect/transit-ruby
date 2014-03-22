require 'spec_helper'

module Transit
  describe RollingCache do
    describe 'encoding' do
      it 'returns the value the first time it sees it' do
        assert { RollingCache.new.encode('abcd') == 'abcd' }
      end

      it 'returns a key the 2nd thru n times it sees a value' do
        rc = RollingCache.new
        assert { rc.encode('abc') == 'abc' }

        key = rc.encode('abc')
        assert { key == '^!' }

        100.times do
          assert { rc.encode('abc') == key }
        end
      end

      it 'keeps track of the number of values encoded' do
        rc = RollingCache.new
        rc.encode('abcd')
        rc.encode('xxxx')
        rc.encode('yyyy')
        assert {rc.size == 3}
      end

      it 'has a default CACHE_SIZE of 94' do
        assert { RollingCache::CACHE_SIZE == 94 }
      end

      it 'can handle CACHE_SIZE different values' do
        rc = RollingCache.new
        RollingCache::CACHE_SIZE.times do |i|
          assert { rc.encode("value#{i}") == "value#{i}" }
        end

        assert { rc.size == RollingCache::CACHE_SIZE }
      end

      it 'resets after CACHE_SIZE different values' do
        rc = RollingCache.new
        (RollingCache::CACHE_SIZE+1).times do |i|
          assert{ rc.encode("value#{i}") == "value#{i}" }
        end

        assert { rc.size == 1 }
      end

      it 'keeps the cache size capped at CACHE_SIZE' do
        sender = RollingCache.new
        receiver = RollingCache.new

        names = random_strings(3, 500)
        (RollingCache::CACHE_SIZE*20).times do |i|
          name = names.sample
          receiver.decode(sender.encode(name))
          assert { sender.size <= RollingCache::CACHE_SIZE }
          assert { receiver.size <= RollingCache::CACHE_SIZE }
        end
      end

      it 'does not cache small strings' do
        sender = RollingCache.new
        receiver = RollingCache.new

        names = random_strings(3, 500)
        2000.times do |i|
          name = names.sample
          assert { receiver.decode(sender.encode(name)) == name }
        end
      end
    end

    describe "decoding" do
      it 'returns the value, given a key that has a value in the cache' do
        rc = RollingCache.new
        rc.encode 'abcd'
        key = rc.encode 'abcd'
        assert { rc.decode(key) == 'abcd' }

      end

      it 'returns the key, given a key that has no matching value in the cache' do
        rc = RollingCache.new
        assert { rc.decode('abcde') == 'abcde' }
      end

      it 'always returns working keys' do
        sender = RollingCache.new
        receiver = RollingCache.new

        names = random_strings(200, 10)

        2000.times do |i|
          name = names.sample
          assert { receiver.decode(sender.encode(name)) == name }
        end
      end
    end
  end
end
