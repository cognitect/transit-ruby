class RollingCache
  FIRST_ORD = 33
  CACHE_SIZE = 96

  def initialize
    clear
  end

  def [](key)
    @key_to_value.fetch(key, key)
  end

  def cache(value)
    return value unless eligable?(value)

    key = @value_to_key[value]
    return key if key


    encache(value)
    value
  end

  def clear
    #puts "clear cache!"

    @key_to_value = {}
    @value_to_key = {}
  end

  def size
    @key_to_value.size
  end

  def cache_full?
    @key_to_value.size >= CACHE_SIZE
  end


  private

  def encache(value)
    #puts "encache: #{value}"
    clear if cache_full?

    i = @key_to_value.size
    key = encode(i)
    @key_to_value[key] = value
    @value_to_key[value] = key
    key
  end

  def eligable?(value)
    value.size >= 3
  end

  def encode(i)
    "^#{(i+33).chr}"
  end

  def decode(s)
    s[1].ord - 33
  end
end
