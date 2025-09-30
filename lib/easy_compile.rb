# frozen_string_literal: true

require_relative "easy_compile/version"

module EasyCompile
  autoload :CLI,              "easy_compile/cli"
  autoload :CompilationTasks, "easy_compile/compilation_tasks"
end
