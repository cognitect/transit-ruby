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

# Supported Rubies

* MRI 2.1.1, 2.1.0, 1.9.3

# Future targets

* MRI 1.8.7 (???)
* jruby >= ???
* rbx >= ???
