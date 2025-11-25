# frozen_string_literal: true

require_relative "lib/cibuildgem/version"

Gem::Specification.new do |spec|
  spec.name = "cibuildgem"
  spec.version = Cibuildgem::VERSION
  spec.authors = ["Shopify"]
  spec.email = ["rails@shopify.com"]

  spec.summary = "Assist developers to distrute gems with precompiled binaries."
  spec.description = <<~MSG
    Gems with native extensions are the main bottleneck for a user when running `bundle install`.
    This gem aims to provide the Ruby community an easy to opt-in and quick way to distribute their
    gems with precompiled binaries.

    This toolchain works with a native CI based compilation approach using GitHub actions. It piggyback on
    top of popular tools in the Ruby ecosystem that maintainers are used to such as Rake Compiler and ruby/setup-ruby.
  MSG
  spec.homepage = "https://github.com/shopify/cibuildwheel"
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
