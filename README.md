transit-ruby
===================

Transit marshalling for Ruby.

```ruby
# io can be any Ruby IO

writer = Transit::Writer.new(io, :json) # or :msgpack
writer.write(obj)

reader = Transit::Reader.new(:json)     # or :msgpack
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
