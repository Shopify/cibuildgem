# frozen_string_literal: true

require_relative "../compilation_tasks"

task = EasyCompile::CompilationTasks.new(!Rake::Task.task_defined?(:package))
task.setup

task "copy:stage:lib" do
  version = RUBY_VERSION.match(/(\d\.\d)/)[1]
  path = "#{task.extension_task.lib_dir}/#{version}"

  cp_r("tmp/#{task.extension_task.cross_platform}/stage/#{path}", path, remove_destination: true)
end
