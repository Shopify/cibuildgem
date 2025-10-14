# frozen_string_literal: true

require_relative "../compilation_tasks"

task = EasyCompile::CompilationTasks.new(!Rake::Task.task_defined?(:package))
task.setup
