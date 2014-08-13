# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "transit-ruby"
  spec.version       = "0.8.dev"
  spec.authors       = ["Russ Olsen","David Chelimsky","Yoko Harada"]
  spec.email         = ["russ@cognitect.com","dchelimsky@cognitect.com","yoko@cognitect.com"]
  spec.summary       = %q{Transit marshalling for Ruby}
  spec.description   = %q{Transit marshalling for Ruby}
  spec.homepage      = "http://github.com/cognitect/transit-ruby"
  spec.license       = "Apache License 2.0"

  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files -- lib/*`.split("\n") + ["README.md","LICENSE",".yardopts",".yard_redcarpet_ext"]
  spec.test_files    = `git ls-files -- spec/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable",       "~> 2.3.6", ">= 2.3.6"
  spec.add_dependency "msgpack",           "~> 0.5.8", ">= 0.5.8"
  spec.add_dependency "oj",                "~> 2.9.9", ">= 2.9.9"
  spec.add_development_dependency "yard",  "~> 0.8.7.4", ">= 0.8.7.4"
  spec.add_development_dependency "redcarpet", "~> 3.1.1", ">= 3.1.1"
  spec.add_development_dependency "yard-redcarpet-ext", "~> 0.0.3", ">= 0.0.3"
  spec.add_development_dependency "rake",  "~> 10.1"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "wrong", "~> 0.7.1", ">= 0.7.1"

  private_key = File.expand_path('~/.gem/transit-ruby-private_key.pem')
  if File.exist?(private_key) && ENV['SIGN'] == 'true'
    spec.signing_key = private_key
    spec.cert_chain = [File.expand_path('~/.gem/transit-ruby-public_cert.pem')]
  end
end
