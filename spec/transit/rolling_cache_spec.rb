require 'spec_helper'

module Transit
  describe RollingCache do

    it 'returns the identifier the first time it sees it' do
      assert{ RollingCache.new.encode('abcd') == 'abcd' }
    end

    it 'keeps track of the number of items encoded' do
      rc = RollingCache.new
      rc.encode('abcd')
      rc.encode('xxxx')
      rc.encode('yyyy')
      assert {rc.size == 3}
    end

    it 'returns a encode id the 2nd thru n times it sees an identifier' do
      rc = RollingCache.new
      assert { rc.encode('abc') == 'abc' }

      key = rc.encode('abc')
      assert { key == '^!' }

      100.times do
        assert{ rc.encode('abc') == key }
      end
    end

    it 'can handle 96 different values' do
      rc = RollingCache.new
      96.times do |i|
        assert{ rc.encode("value#{i}") == "value#{i}" }
      end

      assert { rc.size == RollingCache::CACHE_SIZE }
    end

    it 'can resets after 96 different values' do
      rc = RollingCache.new
      (RollingCache::CACHE_SIZE+1).times do |i|
        assert{ rc.encode("value#{i}") == "value#{i}" }
      end

      assert { rc.size == 1 }
    end

    it 'Returns the value given a key' do
      rc = RollingCache.new
      rc.encode 'abcd'
      key = rc.encode 'abcd'
      assert { rc.decode(key) == 'abcd' }
    end

    it 'Returns the key given it if the key is not in the cache' do
      rc = RollingCache.new
      assert { rc.decode('abcde') == 'abcde' }
    end

    it 'Whatever comes out of the encode method will work as a key' do
      sender = RollingCache.new
      reciever = RollingCache.new

      names = random_strings(200, 10)

      2000.times do |i|
        name = names.sample
        assert { reciever.decode(sender.encode(name)) == name }
      end
    end

    it 'works consistently for small strings which are not cached' do
      sender = RollingCache.new
      reciever = RollingCache.new

      names = random_strings(3, 500)
      2000.times do |i|
        name = names.sample
        assert { reciever.decode(sender.encode(name)) == name }
      end
    end

    it 'keeps the cache at no more than its max size' do
      sender = RollingCache.new
      reciever = RollingCache.new

      names = random_strings(3, 500)
      2000.times do |i|
        name = names.sample
        reciever.decode(sender.encode(name))
	assert { sender.size <= RollingCache::CACHE_SIZE }
	assert { reciever.size <= RollingCache::CACHE_SIZE }
      end
    end

  end
end
