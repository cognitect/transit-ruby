require 'spec_helper'

module Transit
  describe Reader do
    let(:reader) { Reader.new(:json) }

    it "parses a wrapped int" do
      io = StringIO.new('[1]', 'r+')
      assert { reader.read(io) == 1 }
    end

    it "parses a wrapped int (with a block)" do
      io = StringIO.new('[1]', 'r+')
      received = nil
      reader.read(io) {|o| received = o}
      assert { received == 1 }
    end
  end
end
