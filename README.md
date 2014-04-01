transit-ruby
===================

Transit marshalling for Ruby.

```ruby
# io can be any Ruby IO

writer = Transit::Writer.new(io, :json) # :msgpack coming soon ...
writer.write(obj)

reader = Transit::Reader.new(:json)     # :msgpack coming soon ...
reader.read(io)

# or

reader.read(io) {|o| do_something_with(o)}
```
