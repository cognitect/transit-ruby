require 'spec_helper'

describe RollingCache do

  it 'returns the identifier the first time it sees it' do
    assert{ RollingCache.new.cache('abcd') == 'abcd' }
  end

  it 'keeps track of the number of items cached' do
    rc = RollingCache.new
    rc.cache('abcd')
    rc.cache('xxxx')
    rc.cache('yyyy')
    assert {rc.size == 3}
  end

  it 'returns a cache id the 2nd thru n times it sees an identifier' do
    rc = RollingCache.new
    assert { rc.cache('abc') == 'abc' }

    key = rc.cache('abc')
    assert { key == '^!' }

    100.times do
      assert{ rc.cache('abc') == key }
    end
  end

  it 'can handle 96 different values' do
    rc = RollingCache.new
    96.times do |i|
      assert{ rc.cache("value#{i}") == "value#{i}" }
    end

    assert { rc.size == RollingCache::CACHE_SIZE }
  end

  it 'can resets after 96 different values' do
    rc = RollingCache.new
    97.times do |i|
      assert{ rc.cache("value#{i}") == "value#{i}" }
    end

    assert { rc.size == 1 }
  end

  it 'Returns the value given a cache key' do
    rc = RollingCache.new
    rc.cache 'abcd'
    key = rc.cache 'abcd'
    assert { rc[key] == 'abcd' }
  end

  it 'Returns the key given it if the key is not in the cache' do
    rc = RollingCache.new
    assert { rc['abcde'] == 'abcde' }
  end

end
