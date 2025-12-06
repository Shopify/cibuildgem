# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "edouard-dummy_gem"
  spec.version = "0.0.1"
  spec.authors = ["Edouard CHIN"]
  spec.email = ["user@example.org"]
  spec.summary = "A gem that do nothing"
  spec.description = "Don't use it, really."
  spec.license = "MIT"
  spec.files = []
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/hello_world/extconf.rb"]
end
