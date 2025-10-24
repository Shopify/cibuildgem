# frozen_string_literal: true

require_relative "lib/dummy_gem/version"

Gem::Specification.new do |spec|
  spec.name = "edouard-dummy_gem"
  spec.version = DummyGem::VERSION
  spec.authors = ["Edouard CHIN"]
  spec.email = ["chin.edouard@gmail.com"]

  spec.summary = "A gem that do nothing"
  spec.description = "Don't use it, really."
  spec.homepage = "https://example.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/hello_world/extconf.rb"]
end
