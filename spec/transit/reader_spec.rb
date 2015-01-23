# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

module Transit
  describe Reader do
    shared_examples "read without a block" do |type|
      it "reads a single top-level #{type} element" do
        input = {:this => [1,2,3,{:that => "the other"}]}

        io = StringIO.new('', 'w+')
        writer = Transit::Writer.new(type, io)
        writer.write(input)

        reader = Transit::Reader.new(type, StringIO.new(io.string))
        assert { reader.read == input }
      end
    end

    describe "reading without a block" do
      include_examples "read without a block", :json
      include_examples "read without a block", :json_verbose
      include_examples "read without a block", :msgpack
    end

    shared_examples "read with a block" do |type|
      it "reads multiple top-level #{type} elements from a single IO" do
        inputs = ["abc",
                  123456789012345678901234567890,
                  [:this, :that],
                  {:this => [1,2,3,{:that => "the other"}]}]
        outputs = []

        io = StringIO.new('', 'w+')
        writer = Transit::Writer.new(type, io)
        inputs.each {|i| writer.write(i)}
        reader = Transit::Reader.new(type, StringIO.new(io.string))
        if Transit::jruby?
          # Ignore expected EOFException raised after the StringIO is exhausted
          reader.read {|val| outputs << val} rescue nil
        else
          reader.read {|val| outputs << val}
        end

        assert { outputs == inputs }
      end
    end

    describe "reading with a block" do
      include_examples "read with a block", :json
      include_examples "read with a block", :json_verbose
      include_examples "read with a block", :msgpack
    end

    describe 'handler registration' do
      describe 'overrides' do
        describe 'ground types' do
          Decoder::GROUND_TAGS.each do |ground|
            it "prevents override of #{ground} handler" do
              assert {
                rescuing {
                  Reader.new(:json, StringIO.new, :handlers => {ground => Object.new})
                }.message =~ /ground types/ }
            end
          end
        end

        it 'supports override of default string handlers' do
          io = StringIO.new("[\"~rhttp://foo.com\"]","r+")
          reader = Reader.new(:json, io, :handlers => {"r" => Class.new { def from_rep(v) "DECODED: #{v}" end}.new})
          assert { reader.read == ["DECODED: http://foo.com"] }
        end

        it 'supports override of default hash handlers' do
          my_uuid_class = Class.new(String)
          my_uuid = my_uuid_class.new(UUID.new.to_s)
          io = StringIO.new({"~#u" => my_uuid.to_s}.to_json)
          reader = Reader.new(:json, io, :handlers => {"u" => Class.new { define_method(:from_rep) {|v| my_uuid_class.new(v)}}.new})
          assert { reader.read == my_uuid }
        end

        it 'supports override of the default handler' do
          io = StringIO.new("~Xabc".to_json)
          reader = Reader.new(:json, io, :default_handler => Class.new { def from_rep(tag,val) raise "Unacceptable: #{s}" end}.new)
          assert { rescuing {reader.read }.message =~ /Unacceptable/ }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          io = StringIO.new("~D2014-03-15".to_json)
          reader = Reader.new(:json, io, :handlers => {"D" => Class.new { def from_rep(v) Date.parse(v) end}.new})
          assert { reader.read == Date.new(2014,3,15) }
        end

        it 'supports hash based extensions' do
          io = StringIO.new({"~#Times2" => 44}.to_json)
          reader = Reader.new(:json, io, :handlers => {"Times2" => Class.new { def from_rep(v) v * 2 end}.new})
          assert { reader.read == 88 }
        end

        it 'supports hash based extensions that return nil'  do
          io = StringIO.new({"~#Nil" => :anything}.to_json)
          reader = Reader.new(:json, io, :handlers => {"Nil" => Class.new { def from_rep(_) nil end}.new})
          assert { reader.read == nil }
        end

        it 'supports hash based extensions that return false' do
          io = StringIO.new({"~#False" => :anything}.to_json)
          reader = Reader.new(:json, io, :handlers => {"False" => Class.new { def from_rep(_) false end}.new})
          assert { reader.read == false }
        end

        it 'supports complex hash values' do
          io = StringIO.new([
                             {"~#person"=>
                               {"~:first_name" => "Transit","~:last_name" => "Ruby","~:birthdate" => "~D2014-01-02"}},
                             {"^0"=>
                               {"^1" => "Transit","^2" => "Ruby","^3" => "~D2014-01-03"}}].to_json)

          person_handler = Class.new do
            def from_rep(v)
              Person.new(v[:first_name],v[:last_name],v[:birthdate])
            end
          end
          date_handler = Class.new do
            def from_rep(v) Date.parse(v) end
          end
          reader = Reader.new(:json, io,
                              :handlers => {
                                "person" => person_handler.new,
                                "D"      => date_handler.new})
          expected = [Person.new("Transit", "Ruby", Date.new(2014,1,2)),
                      Person.new("Transit", "Ruby", Date.new(2014,1,3))]
          assert { reader.read == expected }
        end
      end

      describe 'Dates/Times' do
        it "delivers a UTC DateTime for a non-UTC date string" do
          io = StringIO.new(["~t2014-04-14T12:20:50.152-05:00"].to_json)
          reader = Reader.new(:json, io)
          expect(Transit::DateTimeUtil.to_millis(reader.read.first)).to eq(Transit::DateTimeUtil.to_millis(DateTime.new(2014,4,14,17,20,50.152,"Z")))
        end
      end

      describe 'edge cases found in generative testing' do
        it 'caches nested structures correctly' do
          io = StringIO.new(["~#cmap",[["~#point",["~n10","~n11"]],"~:foobar",["^1",["~n10","~n13"]],"^2"]].to_json)
          reader = Reader.new(:json, io)
          expected = {TaggedValue.new("point", [10,11]) => :foobar,
                      TaggedValue.new("point", [10,13]) => :foobar}
          assert { reader.read == expected }
        end
      end
    end
  end
end
