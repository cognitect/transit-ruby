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
