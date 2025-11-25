# frozen_string_literal: true

require_relative "lib/cibuildgem/version"

Gem::Specification.new do |spec|
  spec.name = "cibuildgem"
  spec.version = Cibuildgem::VERSION
  spec.authors = ["Shopify"]
  spec.email = ["rails@shopify.com"]

  spec.summary = "Add a summary later"
  spec.description = "Add a description laster"
  spec.homepage = "https://github.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com"

  spec.files = Dir["{exe,lib,scripts}/**/*", "LICENSE.md", "README.md", "lib/cibuildgem/templates/.github/**/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rake-compiler"
  spec.add_dependency "thor"
  spec.add_dependency "prism"
end
