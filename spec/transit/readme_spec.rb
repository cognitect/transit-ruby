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

def write(inputs, type, io, opts={})
  writer = Transit::Writer.new(type, io, :handlers => opts[:write_handlers])      
  inputs.each do |i|
    writer.write(i)
  end
end

def read(type, io, opts={}, &block)
  reader = Transit::Reader.new(type, StringIO.new(io.string), :handlers => opts[:read_handlers])
  reader.read &block
end

def readme(lable, type, inputs, opts={})
  io = StringIO.new('', 'w+')
  write(inputs, type, io, opts)

  it "reads all #{lable} data in a single io" do
    result = []
    read(type, io, opts) { |val| result << val }
    assert { result == inputs }
  end
end

module Transit
  shared_examples "read me" do |type|
    readme("simple", type, ["abc", 123456789012345678901234567890])
  end

  describe "using json" do
    include_examples "read me", :json
  end

  describe "using json_verbose" do
    include_examples "read me", :json_verbose
  end

  describe "using msgpack" do
    include_examples "read me", :msgpack
  end
end
