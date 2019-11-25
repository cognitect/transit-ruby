## Build (internal)

### Version

The build version is automatically incremented.  To determine the
current build version:

    build/version

### Package

    gem install bundler
    bundle install
    bundle exec rake build

### Install locally

    bundle exec rake install

### Docs

To build api documentation:

    gem install yard
    yard

### Release

#### Pre-requisites:

* permission to push gems to https://rubygems.org/gems/transit-ruby
* public and private key files for MRI

To sign the gem for MRI (currently disabled for JRuby), you'll need
to generate public and private keys. Follow the directions from `gem
cert -h` to generate the following files:

    ~/.gem/transit-ruby/gem-private_key.pem
    ~/.gem/transit-ruby/gem-public_cert.pem

Once those are in place, you can run:

    ./build/release

You'll be prompted to confirm MRI and JRuby releases and for cert
passwords for the MRI version.
