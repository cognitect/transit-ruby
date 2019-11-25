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

def nan?(obj)
  obj.respond_to?(:nan?) and obj.nan?
end

def round_trip(obj, type, opts={})
  obj_before = obj

  io = StringIO.new('', 'w+')
  writer = Transit::Writer.new(type, io, :handlers => opts[:write_handlers])
  writer.write(obj)

  # ensure that we don't modify the object being written
  if nan?(obj_before)
    assert { obj.nan? }
  else
    assert { obj == obj_before }
  end
  reader = Transit::Reader.new(type, StringIO.new(io.string), :handlers => opts[:read_handlers])
  reader.read
end

def assert_equal_times(actual,expected)
  return false unless expected.is_a?(Date) || expected.is_a?(Time) || expected.is_a?(DateTime)
  assert { Transit::DateTimeUtil.to_millis(actual) == Transit::DateTimeUtil.to_millis(expected) }
  assert { actual.zone == expected.zone }
end

def assert_nan(actual,expected)
  return false unless nan?(expected)
  expect(actual.respond_to?(:nan?)).to eq(true)
  expect(actual.nan?).to eq(true)
end

def validate(expected, actual)
  assert_equal_times(actual, expected) || assert_nan(actual, expected) || (expect(actual).to eq(expected))
end

def round_trips(label, obj, type, opts={})
  expected = opts[:expected] || obj

  it "round trips #{label} at top level", :focus => !!opts[:focus], :pending => opts[:pending] do
    validate(expected, round_trip(obj, type, opts))
  end

  it "round trips #{label} as a map key", :focus => !!opts[:focus], :pending => opts[:pending] do
    validate(expected, round_trip({obj => 0}, type, opts).keys.first)
  end

  it "round trips #{label} as a map value", :focus => !!opts[:focus], :pending => opts[:pending] do
    validate(expected, round_trip({a: obj}, type, opts).values.first)
  end

  it "round trips #{label} as an array value", :focus => !!opts[:focus], :pending => opts[:pending] do
    validate(expected, round_trip([obj], type, opts).first)
  end
end

module Transit
  PhoneNumber = Struct.new(:area, :prefix, :suffix)
  def PhoneNumber.parse(p)
    area, prefix, suffix = p.split(".")
    PhoneNumber.new(area, prefix, suffix)
  end

  class PhoneNumberHandler
    def tag(_) "P" end
    def rep(p) "#{p.area}.#{p.prefix}.#{p.suffix}" end
    def string_rep(p) rep(p) end
  end

  class PhoneNumberReadHandler
    def from_rep(v) PhoneNumber.parse(v) end
  end

  class PersonReadHandler
    def from_rep(v)
      Person.new(v[:first_name],v[:last_name],v[:birthdate])
    end
  end

  shared_examples "round trips" do |type|
    round_trips("nil", nil, type)
    round_trips("a keyword", random_symbol, type)
    round_trips("a string", random_string, type)
    round_trips("a string starting with ~", "~#{random_string}", type)
    round_trips("a string starting with ^", "^#{random_string}", type)
    round_trips("a string starting with `", "`#{random_string}", type)
    round_trips("true", true, type)
    round_trips("false", false, type)
    round_trips("a small int", 1, type)
    round_trips("a big int", 123456789012345, type)
    round_trips("a very big int", 123456789012345679012345678890, type)
    round_trips("a float", 1234.56, type)
    round_trips("NaN", Float::NAN, type)
    round_trips("Infinity", Float::INFINITY, type)
    round_trips("-Infinity", -Float::INFINITY, type)
    round_trips("a bigdec", BigDecimal("123.45"), type)
    round_trips("an instant (DateTime local)", DateTime.new(2014,1,2,3,4,5, "-5"), type,
                :expected => DateTime.new(2014,1,2, (3+5) ,4,5, "+00:00"))
    round_trips("an instant (DateTime gmt)", DateTime.new(2014,1,2,3,4,5), type)
    round_trips("an instant (Time local)", Time.new(2014,1,2,3,4,5, "-05:00"), type,
                :expected => DateTime.new(2014,1,2, (3+5) ,4,5, "+00:00"))
    round_trips("an instant (Time gmt)", Time.new(2014,1,2,3,4,5, "+00:00"), type,
                :expected => DateTime.new(2014,1,2,3,4,5, "+00:00"))
    round_trips("a Date", Date.new(2014,1,2), type, :expected => DateTime.new(2014,1,2))
    round_trips("a uuid", UUID.new, type)
    round_trips("a link", Link.new(Addressable::URI.parse("http://example.org/search"), "search"), type)
    round_trips("a link", Link.new(Addressable::URI.parse("http://example.org/search"), "search", nil, "image"), type)
    round_trips("a link with string uri", Link.new("http://example.org/search", "search", nil, "image"), type)
    round_trips("a uri (url)", Addressable::URI.parse("http://example.com"), type)
    round_trips("a uri (file)", Addressable::URI.parse("file:///path/to/file.txt"), type)
    round_trips("a bytearray", ByteArray.new(random_string(50)), type)
    round_trips("a Transit::Symbol", Transit::Symbol.new(random_string), type)
    round_trips("a hash w/ stringable keys", {"this" => "~hash", "1" => 2}, type)
    round_trips("a set", Set.new([1,2,3]), type)
    round_trips("a set of sets", Set.new([Set.new([1,2]), Set.new([3,4])]), type)
    round_trips("an array", [1,2,3], type)
    round_trips("a char", TaggedValue.new("c", "x"), type, :expected => "x")
    round_trips("a list", TaggedValue.new("list", [1,2,3]), type, :expected => [1,2,3])
    round_trips("an array of maps w/ cacheable keys", [{"this" => "a"},{"this" => "b"}], type)

    round_trips("edge case chars", %w[` ~ ^ #], type)

    round_trips("an extension scalar", PhoneNumber.new("555","867","5309"), type,
                :write_handlers => {PhoneNumber => PhoneNumberHandler.new},
                :read_handlers  => {"P" => PhoneNumberReadHandler.new})
    round_trips("an extension struct", Person.new("First","Last",:today), type,
                :write_handlers => {Person => PersonHandler.new},
                :read_handlers  => {"person" => PersonReadHandler.new})
    round_trips("a hash with simple values", {'a' => 1, 'b' => 2, 'name' => 'russ'}, type)
    round_trips("a hash with Transit::Symbols", {Transit::Symbol.new("foo") => Transit::Symbol.new("bar")}, type)
    round_trips("a hash with 53 bit ints",  {2**53-1 => 2**53-2}, type)
    round_trips("a hash with 54 bit ints",  {2**53   => 2**53+1}, type)
    round_trips("a map with composite keys", {{a: :b} => {c: :d}}, type)
    round_trips("a TaggedValue", TaggedValue.new("unrecognized",:value), type)
    round_trips("an unrecognized hash encoding", {"~#unrecognized" => :value}, type)
    round_trips("an unrecognized string encoding", "~Xunrecognized", type)

    round_trips("a nested structure (map on top)", {a: [1, [{b: "~c"}]]}, type)
    round_trips("a nested structure (array on top)", [37, {a: [1, [{b: "~c"}]]}], type)
    round_trips("a map that looks like transit data", [{"~#set"=>[1,2,3]},{"~#set"=>[4,5,6]}], type)
    round_trips("a ratio of big value", [{"~#ratio"=>["~n36893488147419103231","~n73786976294838206463"]}], type)
  end

  describe "Transit using json" do
    include_examples "round trips", :json
  end

  describe "Transit using json_verbose" do
    include_examples "round trips", :json_verbose
  end

  describe "Transit using msgpack" do
    include_examples "round trips", :msgpack
  end
end
