# frozen_string_literal: true

require_relative "../compilation_tasks"

task = EasyCompile::CompilationTasks.new(!Rake::Task.task_defined?(:package))

task "easy_compile:setup" do
  task.setup
end

task "copy:stage:lib" do
  version = RUBY_VERSION.match(/(\d\.\d)/)[1]
  dest = File.join(task.extension_task.lib_dir, version)
  src = File.join("tmp", task.extension_task.cross_platform, "stage", dest)

  cp_r(src, dest, remove_destination: true)
end

unless Rake::Task.task_defined?(:test)
  task(:test) do
    raise(RuntimeError, "Don't know how to build task 'test'") unless Rake::Task.task_defined?(:spec)

    Rake::Task[:spec].invoke
  end
end
