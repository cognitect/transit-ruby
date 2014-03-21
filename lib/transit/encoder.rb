require 'uri'
require 'set'

module Transit
  class Encoder
    IDENTITY = ->(v){v}

    def initialize(options={})
      options = default_options.merge(options)
      @encoders = options[:encoders]
      @uuid = options[:uuid]
      @time = options[:time]
    end

    def default_options
      default_encoders = {
        Symbol        => ->(n){"~:#{n}"},
        ClojureSymbol => ->(n){"~'#{n}"},
        Array         => ->(n){n.map {|x| encode(x)}},
        Set           => ->(n){{'~#s' => n.map {|x| encode(x)}}},
        BigDecimal    => ->(n){"~f#{n.to_f}"},
        ByteArray     => ->(n){"~b#{n.to_base64}"},
        UUID          => method(:encode_uuid),
        Hash          => method(:encode_hash),
        Numeric       => method(:encode_numeric),
        Time          => method(:encode_time),
        String        => method(:encode_string),
        URI           => method(:encode_uri),
        Object        => IDENTITY
      }

      {encoders: default_encoders, uuid: :string , time: :string}
    end

    def encode(node)
      node.class.ancestors.each do |a|
        return @encoders[a].call(node) if @encoders[a]
      end
    end

    def encode_uuid(node)
      case @uuid
      when :string
        "~u#{node.to_s}"
      when :hash
        {'~#u' => node.to_s}
      else
        raise "Don't understand #{@uuid} as a uuid encoding."
      end
    end

    def encode_hash(node)
      node.reduce({}) {|h,kv| h.store(encode(kv[0]), encode(kv[1])); h}
    end

    def encode_numeric(node)
      case node
      when Bignum
        {'#i' => node}
      else
        node
      end
    end

    def encode_time(node)
      case @time
      when :string
        "~t#{node.strftime("%FT%H:%M:%S.%LZ")}"
      when :hash
        {'~#t' => node.strftime("%FT%H:%M:%S.%LZ") }
      else
        raise "Don't understand #{@time} as a time encoding."
      end
    end

    def encode_string(s)
      /^\~/ =~ s ? "~#{s}" : s
    end

    def encode_uri(node)
      "~r#{node}"
    end

    def register_encoder(k, &b)
      @encoders[k] = b
    end
  end
end
