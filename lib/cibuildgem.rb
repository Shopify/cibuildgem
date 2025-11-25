# frozen_string_literal: true

require_relative "cibuildgem/version"
require_relative "cibuildgem/errors"

module Cibuildgem
  autoload :CLI,              "cibuildgem/cli"
  autoload :CompilationTasks, "cibuildgem/compilation_tasks"
  autoload :RubySeries,       "cibuildgem/ruby_series"
end
