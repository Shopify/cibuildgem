# frozen_string_literal: true

require_relative "easy_compile/version"
require_relative "easy_compile/errors"

module EasyCompile
  autoload :CLI,              "easy_compile/cli"
  autoload :CompilationTasks, "easy_compile/compilation_tasks"
  autoload :RubySeries,       "easy_compile/ruby_series"
end
