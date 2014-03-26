require 'oj'
require 'msgpack'
require 'uri'

module Transit
  class Json
    def self.write(obj, io)
      writer = JsonWriter.new(io)
      writer.write(obj)
    end

    def self.read(io)
      raise "TBD"
    end
  end

  class JsonWriter
    def initialize(io, encoder=JsonEncoder.new)
      @oj = Oj::StreamWriter.new(io)
      @encoder = encoder
    end

    def write(obj, name=nil)
      case obj
      when Array
        write_array(obj, name)
      when Hash
        write_hash(obj, name)
      else
        write_encoded(@encoder.encode(obj), name)
      end
    end

    def write_array(obj, name=nil)
      name ? @oj.push_array(name) : @oj.push_array
      obj.each {|item| write(item)}
      @oj.pop
    end

    def write_hash(obj, name=nil)
      name ? @oj.push_object(name) : @oj.push_object
      obj.each do |k, v|
        encoded_key = @encoder.encode_key(k)
        write(v, encoded_key)
      end
      @oj.pop
    end

    def write_encoded(encoded_obj, name)
      name ? @oj.push_value(encoded_obj, name) : @oj.push_value(encoded_obj)
    end
  end

  # TBD MessgePack transport
end
