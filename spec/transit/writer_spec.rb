require 'spec_helper'
require 'json'

module Transit
  describe Writer do
    let(:io) { StringIO.new }
    let(:writer) { Writer.new(io, :json) }

    describe "marshaling transit types" do
      def self.bytes
        @bytes ||= SecureRandom.random_bytes
      end

      def self.marshals_scalar(label, value, rep, opts={})
        it "marshals #{label}", :focus => opts[:focus] do
          writer.write(value)
          assert { JSON.parse(io.string) == {"~#'" => rep} }
        end
      end

      def self.marshals_structure(label, value, rep, opts={})
        it "marshals #{label}", :focus => opts[:focus] do
          writer.write(value)
          assert { JSON.parse(io.string) == rep }
        end
      end

      marshals_scalar("a UUID",
                      UUID.new("dda5a83f-8f9d-4194-ae88-5745c8ca94a7"),
                      "~udda5a83f-8f9d-4194-ae88-5745c8ca94a7")
      marshals_scalar("a TransitSymbol", TransitSymbol.new("foo"), "~$foo" )
      marshals_scalar("a Char", Char.new("a"), "~ca")
      marshals_scalar("a ByteArray", ByteArray.new(bytes), "~b#{ByteArray.new(bytes).to_base64}")
      marshals_structure("a list", TransitList.new([1,2,3]), {"~#list" => [1,2,3]})
      marshals_structure("an array of ints", IntsArray.new([1,2,3]), {"~#ints" => [1,2,3]})
      marshals_structure("an array of ints", LongsArray.new([1,2,3]), {"~#longs" => [1,2,3]})
      marshals_structure("an array of ints", FloatsArray.new([1.1,2.2,3.3]), {"~#floats" => [1.1,2.2,3.3]})
      marshals_structure("an array of ints", DoublesArray.new([1.1,2.2,3.3]), {"~#doubles" => [1.1,2.2,3.3]})
      marshals_structure("an array of ints", BoolsArray.new([true,false,true]), {"~#bools" => [true,false,true]})
      marshals_structure("a TaggedValue", TaggedValue.new("tag", "value"), {"tag" => "value"})
    end

    describe "illegal conditions" do
      it "raises when a handler provides nil as a tag" do
        handler = Class.new do
          def tag(_) nil end
        end
        writer.register(Date, handler)
        assert { rescuing { writer.write(Date.today) }.message =~ /must provide a non-nil tag/ }
      end
    end
  end
end
