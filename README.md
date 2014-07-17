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
==========> "[\"~#'\",\"abc\"]\n[\"~#'\",\"~n123456789012345678901234567890\"]\n"
irb(2.1.1): reader = Transit::Reader.new(:json, StringIO.new(io.string))
==========> #<Transit::Reader:0x007faab2db48e0 @reader=#<Transit::JsonUnmarshaler:0x007faab2dae030 @..........(snip)..........
irb(2.1.1): reader.read {|val| puts val}
abc
123456789012345678901234567890
```

## Default Type Mapping


|Transit type|Write accepts|Read returns|Example(write)|Example(read)|
|------------|-------------|------------|--------------|-------------|
|null|nil|nil|nil|nil|
|string|String|String|"abc"|"abc"|
|boolean|true, false|true, false|false|false|
|integer|Fixnum, Bignum|Fixnum, Bignum|123|123|
|decimal|Float|Float|123.456|123.456|
|keyword|Symbol|Symbol|:abc|:abc|
|symbol|Transit::Symbol|Transit::Symbol|Transit::Symbol.new("foo")|`#<Transit::Symbol "foo">`|
|big decimal|BigDecimal|BigDecimal|BigDecimal.new("2**64")|`#<BigDecimal:7f9e6d33c558>`|
|big integer|Fixnum, Bignum|Fixnum, Bignum|2**128|340282366920938463463374607431768211456|
|time|DateTime, Date, Time|DateTime|DateTime.now|`#<DateTime: 2014-07-15T15:52:27+00:00 ((2456854j,57147s,23000000n),+0s,2299161j)>`|
|uri|Addressable::URI, URI|Addressable::URI|Addressable::URI.parse("http://example.com")|`#<Addressable::URI:0x3fc0e20390d4 URI:http://example.com>`|
|uuid|Transit::UUID|Transit::UUID|Transit::UUID.new|`#<Transit::UUID "defa1cce-f70b-4ddb-bb6e-b6ac817d8bc8">`|
|char|Transit::TaggedValue|String|Transit::TaggedValue.new("c", "a")|"a"|
|array|Array|Array|[1, 2, 3]|[1, 2, 3]|
|list|Transit::TaggedValue|Array|Transit::TaggedValue.new("list", [1, 2, 3])|[1, 2, 3]|
|set|Set|Set|Set.new([1, 2, 3])|`#<Set: {1, 2, 3}>`|
|map|Hash|Hash|`{a: 1, b: 2, c: 3}`|`{:a=>1, :b=>2, :c=>3}`|
|bytes|Transit::ByteArray|Transit::ByteArray|Transit::ByteArray.new("base64")|base64|
|link|Transit::Link|Transit::Link|Transit::Link.new(Addressable::URI.parse("http://example.org/search"), "search")|`#<Transit::Link:0x007f81c405b7f0 @values={"href"=>#<Addressable::URI:0x3fc0e202dfb8 URI:http://example.org/search>, "rel"=>"search", "name"=>nil, "render"=>nil, "prompt"=>nil}>`|

## Custom Handlers

### Custom Write Handlers

Implement `tag`, `rep(obj)` and `string_rep(obj)` methods. For example:

```ruby
PhoneNumber = Struct.new(:area, :prefix, :suffix)

class PhoneNumberWriteHandler
  def tag(_) "P" end
  def rep(o) "#{o.area}.#{o.prefix}.#{o.suffix}" end
  def string_rep(o) rep(o) end
end
```

### Custom Read Handlers

Implement `from_rep(rep)` method. For example:

```ruby
class PhoneNumberReadHandler
  def from_rep(rep)
    area, prefix, suffix = rep.split(".").map(&:to_i)
    PhoneNumber.new(area, prefix, suffix)
  end
end
```

### Example use

```ruby
io = StringIO.new('', 'w+')
writer = Transit::Writer.new(:json, io,
                             :handlers => {PhoneNumber => PhoneNumberWriteHandler.new})
writer.write(PhoneNumber.new(555,867,5309))

reader = Transit::Reader.new(:json, StringIO.new(io.string),
                             :handlers  => {"P" => PhoneNumberReadHandler.new})
p reader.read
```

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
