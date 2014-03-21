require 'oj'
require 'msgpack'
require 'uri'

module Transit
  module Transports
    TRANSPORT = :json

    class Json
      def read(source, decoder=nil)
        decoder ||= ::Transit::Decoder.new
        encoded = Oj.load(source)
        decoder.decode(encoded)
      end

      def write(obj, io=nil, encoder=nil)
        encoder ||= ::Transit::Encoder.new(time: :string, uuid: :string)
        encoded = encoder.encode(obj)
        json = Oj.dump(encoded)

        if io
          io.write(json)
          io.flush
          return nil
        end
        json
      end
    end

    class MsgPack
      def read(source, decoder=nil)
        decoder ||= ::Transit::Decoder.new(time: :hash, uuid: :hash)
        encoded = MessagePack.load(source)
        decoder.decode(encoded)
      end

      def write(obj, io=nil, encoder=nil)
        encoder ||= ::Transit::Encoder.new(time: :string, uuid: :string)
        encoded = encoder.encode(obj)

        if io
          MessagePack.dump(encoded, io)
          io.flush
          return nil
        end
        MessagePack.dump(encoded)
      end
    end
  end
end
