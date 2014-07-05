# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'

module Transit
  describe Reader do
    def read(value, &block)
      reader = Reader.new(:json, StringIO.new(value.to_json, 'r+'))
      reader.read &block
    end

    it 'reads without a block' do
      assert { read([1,2,3]) == [1,2,3] }
    end

    it 'reads with a block' do
      result = nil
      read([1,2,3]) {|v| result = v}
      assert { result == [1,2,3] }
    end

    describe 'handler registration' do
      it 'requires a lambda w/ arity 1' do
        assert { rescuing { Reader.new(:json, StringIO.new, :handlers => {"D" => ->(s,t){}}) }.
          message =~ /arity/ }
      end

      describe 'overrides' do
        describe 'ground types' do
          Decoder::GROUND_TAGS.each do |ground|
            it "prevents override of #{ground} handler" do
              assert {
                rescuing {
                  Reader.new(:json, StringIO.new, :handlers => {ground => ->(_){}})
                }.message =~ /ground types/ }
            end
          end
        end

        it 'supports override of default string handlers' do
          io = StringIO.new("[\"~rhttp://foo.com\"]","r+")
          reader = Reader.new(:json, io, :handlers => {"r" => ->(r){"DECODED: #{r}"}})
          assert { reader.read == ["DECODED: http://foo.com"] }
        end

        it 'supports override of default hash handlers' do
          my_uuid_class = Class.new(String)
          my_uuid = my_uuid_class.new(UUID.new.to_s)
          io = StringIO.new({"~#u" => my_uuid.to_s}.to_json)
          reader = Reader.new(:json, io, :handlers => {"u" => ->(u){my_uuid_class.new(u)}})
          assert { reader.read == my_uuid }
        end

        it 'supports override of the default handler' do
          io = StringIO.new("~Xabc".to_json)
          reader = Reader.new(:json, io, :default_handler => ->(tag,val){raise "Unacceptable: #{s}"})
          assert { rescuing {reader.read }.message =~ /Unacceptable/ }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          io = StringIO.new("~D2014-03-15".to_json)
          reader = Reader.new(:json, io, :handlers => {"D" => ->(s){Date.parse(s)}})
          assert { reader.read == Date.new(2014,3,15) }
        end

        it 'supports hash based extensions' do
          io = StringIO.new({"~#Times2" => 44}.to_json)
          reader = Reader.new(:json, io, :handlers => {"Times2" => ->(d){d * 2}})
          assert { reader.read == 88 }
        end

        it 'supports hash based extensions that return nil'  do
          io = StringIO.new({"~#Nil" => :anything}.to_json)
          reader = Reader.new(:json, io, :handlers => {"Nil" => ->(_){nil}})
          assert { reader.read == nil }
        end

        it 'supports hash based extensions that return false' do
          io = StringIO.new({"~#False" => :anything}.to_json)
          reader = Reader.new(:json, io, :handlers => {"False" => ->(_){false}})
          assert { reader.read == false }
        end

        it 'supports complex hash values' do
          io = StringIO.new([
                             {"~#person"=>
                               {"~:first_name" => "Transit","~:last_name" => "Ruby","~:birthdate" => "~D2014-01-02"}},
                             {"^!"=>
                               {"^\"" => "Transit","^#" => "Ruby","^$" => "~D2014-01-03"}}].to_json)

          reader = Reader.new(:json, io,
                              :handlers => {
                                "person" => ->(p){Person.new(p[:first_name],p[:last_name],p[:birthdate])},
                                "D"      => ->(s){Date.parse(s)}
                              })
          expected = [Person.new("Transit", "Ruby", Date.new(2014,1,2)),
                      Person.new("Transit", "Ruby", Date.new(2014,1,3))]
          assert { reader.read == expected }
        end
      end
    end
  end
end
