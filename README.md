transit-ruby
===================

Transit is a data format and a set of libraries for conveying
values between applications written in different languages. This
library provides support for marshalling Transit data to/from Ruby.

[Rationale](point-me-somewhere)<br>
[API docs](http://rubydoc.info/gems/transit-ruby)<br>
[Specification](https://github.com/cognitect/transit-format)

## Releases and Dependency Information

* Latest release: TBD
* [All Released Versions](https://rubygems.org/gems/transit-ruby)

```sh
gem install transit-ruby
```

## Usage

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

## Type Mapping

### transit -> standard (or at least common) Ruby types

* transit URI         => Addressable::URI
* transit instances   => DateTime
* transit big integer => Integer (Fixnum or Bignum, handled internally
  by Ruby)

### built-in extension types

* Transit::ByteArray
* Transit::Symbol
* Transit::UUID
* Transit::Link
* Transit::TaggedValue

## Typed arrays, lists, and chars

The [transit spec](https://github.com/cognitect/transit-format)
defines several semantic types that map to more general types in Ruby:

* typed arrays (ints, longs, doubles, floats, bools) map to Arrays
* lists map to Arrays
* chars map to Strings

When a Transit::Reader encounters an of these (e.g. <code>{"ints" =>
[1,2,3]}</code>) it delivers just the appropriate object to the app
(e.g. <code>[1,2,3]</code>).

Use a TaggedValue to write these out if it will benefit a consuming
app e.g.:

```ruby
writer.write(TaggedValue.new("ints", [1,2,3]))
```

## Custom Read Handlers

Coming soon ...

## Custom Write Handlers

Coming soon ...

## Supported Rubies

* MRI 1.9.3, 2.0.0, 2.1.0, 2.1.1, 2.1.2

## Contributing

Please discuss potential problems or enhancements on the
[transit-format mailing list](https://groups.google.com/forum/#!forum/transit-format). Issues
should be filed using GitHub issues for this project.

Contributing to Cognitect projects requires a signed
[Cognitect Contributor Agreement](http://cognitect.com/contributing).


## Copyright and License

Copyright © 2014 Cognitect

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.
See the License for the specific language governing permissions and
limitations under the License.
