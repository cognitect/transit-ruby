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
      marshals_scalar("a Fixnum", 9007199254740999, "~i9007199254740999")
      marshals_scalar("a Bignum", 9223372036854775806, "~n9223372036854775806")
      marshals_scalar("a ByteArray", ByteArray.new(bytes), "~b#{ByteArray.new(bytes).to_base64}")
      marshals_structure("a list", TransitList.new([1,2,3]), {"~#list" => [1,2,3]})
      marshals_structure("a link", Link.new("href", "rel", nil, "link", nil),
                         {"~#link" => ["href", "rel", nil, "link", nil]})
      marshals_structure("an array of ints", IntsArray.new([1,2,3]), {"~#ints" => [1,2,3]})
      marshals_structure("an array of ints", LongsArray.new([1,2,3]), {"~#longs" => [1,2,3]})
      marshals_structure("an array of ints", FloatsArray.new([1.1,2.2,3.3]), {"~#floats" => [1.1,2.2,3.3]})
      marshals_structure("an array of ints", DoublesArray.new([1.1,2.2,3.3]), {"~#doubles" => [1.1,2.2,3.3]})
      marshals_structure("an array of ints", BoolsArray.new([true,false,true]), {"~#bools" => [true,false,true]})
      marshals_structure("a TaggedValue", TaggedValue.new("tag", "value"), {"~#tag" => "value"})
    end

    describe "custom handlers" do
      it "raises when a handler provides nil as a tag" do
        handler = Class.new do
          def tag(_) nil end
        end
        writer = Writer.new(:json_verbose, io, :handlers => {Date => handler.new})
        assert { rescuing { writer.write(Date.today) }.message =~ /must provide a non-nil tag/ }
      end

      it "supports custom handlers for core types" do
        handler = Class.new do
          def tag(_) "s" end
          def rep(s) "MYSTRING: #{s}" end
          def string_rep(s) rep(s) end
        end
        writer = Writer.new(:json_verbose, io, :handlers => {String => handler.new})
        writer.write("this")
        assert { JSON.parse(io.string).values.first == "MYSTRING: this" }
      end

      it "supports custom handlers for custom types" do
        handler = Class.new do
          def tag(_) "person" end
          def rep(s) {:first_name => s.first_name} end
          def string_rep(s) s.first_name end
        end
        writer = Writer.new(:json_verbose, io, :handlers => {Person => handler.new})
        writer.write(Person.new("Russ"))
        assert { JSON.parse(io.string) == {"~#person" => { "~:first_name" => "Russ" } } }
      end

      it "supports verbose handlers" do
        phone_class = Class.new do
          attr_reader :p
          def initialize(p)
            @p = p
          end
        end
        handler = Class.new do
          def tag(_) "phone" end
          def rep(v) v.p end
          def string_rep(v) v.p.to_s end
          def verbose_handler
            Class.new do
              def tag(_) "phone" end
              def rep(v) "PHONE: #{v.p}" end
              def string_rep(v) rep(v) end
            end
          end
        end

        writer = Writer.new(:json, io, :handlers => {phone_class => handler.new})
        writer.write(phone_class.new(123456789))
        assert { JSON.parse(io.string) == {"~#phone" => 123456789} }

        io.rewind

        writer = Writer.new(:json_verbose, io, :handlers => {phone_class => handler.new})
        writer.write(phone_class.new(123456789))
        assert { JSON.parse(io.string) == {"~#phone" => "PHONE: 123456789"} }
      end
    end

    describe "JSON formats" do
      describe "JSON" do
        let(:writer) { Writer.new(:json, io) }

        it "writes a map as an array prefixed with '^ '" do
          writer.write({:a => :b, 3 => 4})
          assert { JSON.parse(io.string) == ["^ ", "~:a", "~:b", 3, 4] }
        end

        it "writes a single-char tagged-value as a string" do
          writer.write([TaggedValue.new("a","bc")])
          assert { JSON.parse(io.string) == ["~abc"] }
        end

        it "writes a multi-char tagged-value as a map" do
          writer.write(TaggedValue.new("abc","def"))
          assert { JSON.parse(io.string) == {"~#abc" => "def"} }
        end

        it "writes a Date as an encoded hash with ms" do
          writer.write([Date.new(2014,1,2)])
          assert { JSON.parse(io.string) == ["~m1388620800000"] }
        end

        it "writes a Time as an encoded hash with ms" do
          writer.write([(Time.at(1388631845) + 0.678)])
          assert { JSON.parse(io.string) == ["~m1388631845678"] }
        end

        it "writes a DateTime as an encoded hash with ms" do
          writer.write([(Time.at(1388631845) + 0.678).to_datetime])
          assert { JSON.parse(io.string) == ["~m1388631845678"] }
        end
      end

      describe "JSON_VERBOSE" do
        let(:writer) { Writer.new(:json_verbose, io) }

        it "does not use the cache" do
          writer.write([{"this" => "that"}, {"this" => "the other"}])
          assert { JSON.parse(io.string) == [{"this" => "that"}, {"this" => "the other"}] }
        end

        it "writes a single-char tagged-value as a string" do
          writer.write([TaggedValue.new("a","bc")])
          assert { JSON.parse(io.string) == ["~abc"] }
        end

        it "writes a multi-char tagged-value as a map" do
          writer.write(TaggedValue.new("abc","def"))
          assert { JSON.parse(io.string) == {"~#abc" => "def"} }
        end

        it "writes a Date as an encoded human-readable strings" do
          writer.write([Date.new(2014,1,2)])
          assert { JSON.parse(io.string) == ["~t2014-01-02T00:00:00.000Z"] }
        end

        it "writes a Time as an encoded human-readable strings" do
          writer.write([(Time.at(1388631845) + 0.678)])
          assert { JSON.parse(io.string) == ["~t2014-01-02T03:04:05.678Z"] }
        end

        it "writes a DateTime as an encoded human-readable strings" do
          writer.write([(Time.at(1388631845) + 0.678).to_datetime])
          assert { JSON.parse(io.string) == ["~t2014-01-02T03:04:05.678Z"] }
        end
      end
    end
  end
end
