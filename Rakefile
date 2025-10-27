# frozen_string_literal: true

require "bundler/gem_tasks"

begin
  require "minitest/test_task"

  Minitest::TestTask.create do |t|
    t.test_globs = ["test/**/*_test.rb"]
  end
rescue LoadError
  # This begin/rescue is temporary. The gem isn't pusblished to RubyGems so to install
  # it the GitHub action clones the repo and runs `rake install`, without running a `bundle install` first.
end

task default: :test
