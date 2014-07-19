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

Assuming you have permission to publish the gem and access to the
public and private keys, as well as the password used to generate
them, start by placing the pubic and private keys in ~/.gem:

    $ ls ~/.gem | grep transit-ruby
    transit-ruby-private_key.pem
    transit-ruby-public_cert.pem

Then:

    rake release

You'll be prompted for the password during this build.
