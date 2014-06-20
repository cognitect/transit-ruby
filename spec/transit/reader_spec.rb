# Copyright (c) Cognitect, Inc.
# All rights reserved.

require 'spec_helper'

module Transit
  describe Reader do
    let(:reader) { Reader.new(:json) }

    def read(value)
      reader.read(StringIO.new(value.to_json, 'r+'))
    end

    describe 'decoder registration' do
      it 'requires a lambda w/ arity 1' do
        assert { rescuing { reader.register("~D") {|s,t|} }.
          message =~ /arity/ }
      end

      describe 'overrides' do
        it 'supports override of default string decoders' do
          reader.register("r") {|r| "DECODED: #{r}"}
          assert { read("~rhttp://foo.com") == "DECODED: http://foo.com" }
        end

        it 'supports override of default hash decoders' do
          my_uuid_class = Class.new(String)
          my_uuid = my_uuid_class.new(UUID.new.to_s)

          reader.register("u") {|u| my_uuid_class.new(u)}
          assert { read({"~#u" => my_uuid.to_s}) == my_uuid }
        end

        it 'supports override of the default encoder for strings' do
          reader.register(:default_decoder) {|tag,val| raise "Unacceptable: #{s}"}
          assert { rescuing { read("~Xabc") }.message =~ /Unacceptable/ }
        end

        it 'supports override of the default encoder for hashes' do
          reader.register(:default_decoder) {|tag,val| raise "Unacceptable: #{s}"}
          assert { rescuing { read({"~#XYZ" => "abc"}) }.message =~ /Unacceptable/ }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          reader.register("D") {|s| Date.parse(s)}
          assert { read("~D2014-03-15") == Date.new(2014,3,15) }
        end

        it 'supports hash based extensions' do
          reader.register("Times2") {|d| d * 2}
          assert { read({"~#Times2" => 44}) == 88 }
        end

        it 'supports hash based extensions that return nil'  do
          reader.register("Nil") {|_| nil}
          assert { read({"~#Nil" => :anything }) == nil }
        end

        it 'supports hash based extensions that return false' do
          reader.register("False") {|_| false}
          assert { read({"~#False" => :anything }) == false }
        end

        it 'supports complex hash values' do
          reader.register("person") {|p| Person.new(p[:first_name],p[:last_name],p[:birthdate])}
          reader.register("D") {|s| Date.parse(s)}

          expected = [Person.new("Transit", "Ruby", Date.new(2014,1,2)),
                      Person.new("Transit", "Ruby", Date.new(2014,1,3))]
          actual   = read([
                                     {"~#person"=>{"~:first_name" => "Transit","~:last_name" => "Ruby","~:birthdate" => "~D2014-01-02"}},
                                     {"^!"=>{"^\"" => "Transit","^#" => "Ruby","^$" => "~D2014-01-03"}}
                                    ])
          assert { actual == expected }
        end
      end
    end
  end
end
