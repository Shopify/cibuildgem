# frozen_string_literal: true

require_relative "dummy_gem/version"

begin
  ruby_version = /(\d+\.\d+)/.match(RUBY_VERSION)

  require "#{ruby_version}/hello_world"
rescue LoadError
  require "hello_world"
end

module DummyGem
  class Error < StandardError; end
  # Your code goes here...
end
