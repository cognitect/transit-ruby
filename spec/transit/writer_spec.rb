# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'
require 'json'

module Transit
  describe Writer do
    let(:io) { StringIO.new }
    let(:writer) { Writer.new(:json_verbose, io) }

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

    describe "handler registration" do
      it "raises when a handler provides nil as a tag" do
        handler = Class.new do
          def tag(_) nil end
        end
        writer.register(Date, handler)
        assert { rescuing { writer.write(Date.today) }.message =~ /must provide a non-nil tag/ }
      end

      it "supports registration of handlers for core types" do
        handler = Class.new do
          def tag(_) "s" end
          def rep(s) "MYSTRING: #{s}" end
          def string_rep(s) rep(s) end
        end
        writer.register(String, handler)
        writer.write("this")
        assert { JSON.parse(io.string).values.first == "MYSTRING: this" }
      end

      it "supports registration of handlers for custom types" do
        handler = Class.new do
          def tag(_) "person" end
          def rep(s) {:first_name => s.first_name} end
          def string_rep(s) s.first_name end
        end
        writer.register(Person, handler)
        writer.write(Person.new("Russ"))
        assert { JSON.parse(io.string) == {"~#person" => { "~:first_name" => "Russ" } } }
      end
    end

    describe "JSON formats" do
      describe "JSON" do
        let(:writer) { Writer.new(:json, io) }

        it "writes a map as an array prefixed with '^ '" do
          writer.write({:a => :b, 3 => 4})
          assert { JSON.parse(io.string) == ["^ ", "~:a", "~:b", 3, 4] }
        end

        it "writes a tagged-value as a map"

        it "writes a Date as an encoded hash with ms" do
          writer.write([Date.new(2014,1,2)])
          assert { JSON.parse(io.string) == ["~m1388620800000"] }
        end

        it "writes a Time as an encoded hash with ms" do
          writer.write([Time.new(2014,1,2,3,4,5.678,"+00:00")])
          assert { JSON.parse(io.string) == ["~m1388631845678"] }
        end

        it "writes a DateTime as an encoded hash with ms" do
          writer.write([DateTime.new(2014,1,2,3,4,5.678)])
          assert { JSON.parse(io.string) == ["~m1388631845678"] }
        end
      end

      describe "JSON_VERBOSE" do
        let(:writer) { Writer.new(:json_verbose, io) }

        it "does not use the cache" do
          writer.write([{"this" => "that"}, {"this" => "the other"}])
          assert { JSON.parse(io.string) == [{"this" => "that"}, {"this" => "the other"}] }
        end

        it "writes a tagged-value as a map"

        it "writes a Date as an encoded human-readable strings" do
          writer.write([Date.new(2014,1,2)])
          assert { JSON.parse(io.string) == ["~t2014-01-02T00:00:00.000Z"] }
        end

        it "writes a Time as an encoded human-readable strings" do
          writer.write([Time.new(2014,1,2,3,4,5.678,"+00:00")])
          assert { JSON.parse(io.string) == ["~t2014-01-02T03:04:05.678Z"] }
        end

        it "writes a DateTime as an encoded human-readable strings" do
          writer.write([DateTime.new(2014,1,2,3,4,5.678)])
          assert { JSON.parse(io.string) == ["~t2014-01-02T03:04:05.678Z"] }
        end
      end
    end
  end
end
