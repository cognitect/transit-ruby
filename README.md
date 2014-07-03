transit-ruby
===================

Transit is an extensible data notation.
See [https://github.com/cognitect/transit-format](https://github.com/cognitect/transit-format) for details about Transit specification.
Transit-ruby is an encoder/decoder for Ruby.

```ruby
# io can be any Ruby IO

writer = Transit::Writer.new(:json, io) # or :json-verbose, :msgpack
writer.write(obj)

reader = Transit::Reader.new(:json, io) # or :msgpack
reader.read

# or

reader.read {|o| do_something_with(o)}
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
irb(2.1.1): reader.read {|o| puts o}
abc
123456789012345678901234567890
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

## Running the tests

```sh
bundle exec rake spec
```

## Build

```sh
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
