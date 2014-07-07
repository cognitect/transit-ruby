transit-ruby
===================

Transit is a format and set of libraries for conveying values between
applications written in different programming languages. See
[https://github.com/cognitect/transit-format](https://github.com/cognitect/transit-format)
for details.

transit-ruby is a Transit encoder/decoder library for Ruby.

```ruby
# io can be any Ruby IO

writer = Transit::Writer.new(:json, io) # or :json-verbose, :msgpack
writer.write(value)

reader = Transit::Reader.new(:json, io) # or :msgpack
reader.read

# or

reader.read {|val| do_something_with(val)}
```

For example:

```
irb(2.1.1): io = StringIO.new('', 'w+')
==========> #<StringIO:0x007faab2ec3970>
irb(2.1.1): writer = Transit::Writer.new(:json, io)
==========> #<Transit::Writer:0x007faab2e8c1c8 @marshaler=#<Transit::JsonMarshaler:0x007faab2e1a168..........(snip)..........
irb(2.1.1): writer.write("abc")
==========> nil
irb(2.1.1): writer.write(123456789012345678901234567890)
==========> nil
irb(2.1.1): io.string
==========> "{\"~#'\":\"abc\"}\n{\"~#'\":\"~n123456789012345678901234567890\"}\n"
irb(2.1.1): reader = Transit::Reader.new(:json, StringIO.new(io.string))
==========> #<Transit::Reader:0x007faab2db48e0 @reader=#<Transit::JsonUnmarshaler:0x007faab2dae030 @..........(snip)..........
irb(2.1.1): reader.read {|val| puts val}
abc
123456789012345678901234567890
```

# Typed arrays

The transit spec defines typed arrays (ints, longs, doubles, floats,
and bools). Since these are not supported in the Ruby language, when a
Transit::Reader encounters a typed array (<code>{"ints" =>
[1,2,3]}</code>) it delivers just the array to the app
(<code>[1,2,3]</code>).

If, however, your app would benefit from writing an array of ints
(e.g. another process uses a language like Java, which does support arrays
of primitve types), you can write them out as TaggedValues:

```ruby
TaggedValue.new("ints", [1,2,3])
```

# Supported Rubies

* MRI 1.9.3, 2.0.0, 2.1.0, 2.1.1, 2.1.2

# Development

## Setup

Transit Ruby uses transit as a submodule to get at the transit
exemplar files. The tests will not run without the exemplar files.
You need to run a couple of git commands to set up the transit
git submodule:

```sh
git submodule init
git submodule update
```

## Benchmarks

```sh
./bin/seattle-benchmark
```

## Running the examples

```sh
bundle exec rake spec
```

## Build

```sh
bundle exec rake build

# or, if you want to install the gem locally ...

bundle exec rake build
```

The version number is automatically incremented based on the number of commits.
The command below shows what version number will be applied.

```sh
build/revision
```

# Copyright and License

Copyright © 2014 Cognitect

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
