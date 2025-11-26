# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "foo"
  spec.version = "0.0.1"
  spec.authors = ["John Doe"]
  spec.email = ["john@example.com"]

  spec.summary = "Not important"
  spec.description = "Not important"
  spec.homepage = "https://github.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = []
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/foo.rb"]
end
