transit-ruby
===================

Transit is a data format and a set of libraries for conveying
values between applications written in different languages. This
library provides support for marshalling Transit data to/from Ruby.

[Rationale](http://blog.cognitect.com/blog/2014/7/22/transit)<br>
[API docs](http://rubydoc.info/gems/transit-ruby)<br>
[Specification](https://github.com/cognitect/transit-format)

This implementation's major.minor version number corresponds to the
version of the Transit specification it supports.

_NOTE: Transit is intended primarily as a wire protocol for transferring data between applications. If storing Transit data durably, readers and writers are expected to use the same version of Transit and you are responsible for migrating/transforming/re-storing that data when and if the transit format changes._

## Contributing

This library is open source, developed internally by Cognitect. We welcome discussions of potential problems and enhancement suggestions on the [transit-format mailing list](https://groups.google.com/forum/#!forum/transit-format). Issues can be filed using GitHub [issues](https://github.com/cognitect/transit-ruby/issues) for this project. Because transit is incorporated into products and client projects, we prefer to do development internally and are not accepting pull requests or patches.

## Releases and Dependency Information

See https://rubygems.org/gems/transit-ruby

## Install

```sh
gem install transit-ruby
```

## Basic Usage

```ruby
# io can be any Ruby IO

writer = Transit::Writer.new(:json, io) # or :json_verbose, :msgpack
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

## Custom Handlers

### Custom Write Handlers

Implement `tag`, `rep(obj)` and `string_rep(obj)` methods. For example:

```ruby
Point = Struct.new(:x,:y) do
  def to_a; [x,y] end
end

class PointWriteHandler
  def tag(_) "point" end
  def rep(o) o.to_a  end
  def string_rep(_) nil end
end
```

### Custom Read Handlers

Implement `from_rep(rep)` method. For example:

```ruby
class PointReadHandler
  def from_rep(rep)
    Point.new(*rep)
  end
end
```

### Example Usage

```ruby
io = StringIO.new('', 'w+')
writer = Transit::Writer.new(:json, io,
                             :handlers => {Point => PointWriteHandler.new})
writer.write(Point.new(37,42))

p io.string.chomp
#=> "[\"~#point\",[37,42]]"

reader = Transit::Reader.new(:json, StringIO.new(io.string),
                             :handlers  => {"point" => PointReadHandler.new})
p reader.read
#=> #<struct Point x=37, y=42>
```

See
[Transit::WriteHandlers](http://rubydoc.info/gems/transit-ruby/Transit/WriteHandlers)
for more info.

## Default Type Mapping

|Transit type|Write accepts|Read returns|Example(write)|Example(read)|
|------------|-------------|------------|--------------|-------------|
|null|nil|nil|nil|nil|
|string|String|String|"abc"|"abc"|
|boolean|true, false|true, false|false|false|
|integer|Integer|Integer|123|123|
|decimal|Float|Float|123.456|123.456|
|keyword|Symbol|Symbol|:abc|:abc|
|symbol|Transit::Symbol|Transit::Symbol|Transit::Symbol.new("foo")|`#<Transit::Symbol "foo">`|
|big decimal|BigDecimal|BigDecimal|BigDecimal("2**64")|`#<BigDecimal:7f9e6d33c558>`|
|big integer|Integer|Integer|2**128|340282366920938463463374607431768211456|
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

### Additional types (not required by the [transit-format](https://github.com/cognitect/transit-format) spec)

|Semantic type|Write accepts|Read returns|Example(write)|Example(read)|
|------------|-------------|------------|--------------|-------------|
|ratio|Rational|Rational|Rational(1, 3)|Rational(1, 3)|

## Tested Ruby Versions

* MRI 2.1.10, 2.2.7, 2.3.4, 2.4.0, 2.4.1, 2.6.0..3
* JRuby 1.7.13..16

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
