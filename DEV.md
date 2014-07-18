### Development setup

    gem install bundler
    bundle install

Transit Ruby uses transit as a submodule to get at the transit
exemplar files. The tests will not run without the exemplar files.
You need to run a couple of git commands to set up the transit
git submodule:

    git submodule init
    git submodule update

### Run rspec examples

    rspec

## Benchmarks

    ./bin/benchmark # reads transit data in json and json-verbose formats
