require 'spec_helper'

module Transit
  class JsonUnmarshaler
    def initialize(io)
      @oj = Oj::StreamReader.new(io)
    end
  end

  class Reader
    def initialize(io, type)
      @reader = JsonUnmarshaler.new(io)
    end

    def read(obj)
      @unmarshaler.unmarshal
    end
  end

  describe Reader do
    let(:io) { StringIO.new('', 'r+') }
    let(:reader) { Reader.new(io, :json) }

    it "parses an array w/ an int" do
      io.write("[1]")
    end
  end
end
