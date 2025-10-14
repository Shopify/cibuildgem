# frozen_string_literal: true

require "thor"
require "rake/extensiontask"

module EasyCompile
  class CLI < Thor
    include Thor::Actions

    source_root(File.expand_path("templates", __dir__))
    default_command :compile_and_test
    class_option :gemspec, type: :string, required: false, desc: "The gemspec of the gem. Defaults to the one from the root of the project."

    def self.exit_on_failure?
      true
    end

    desc "compile_and_test", "Compile a gem's native extension based on its gemspec and run the test suite."
    def compile_and_test
      run_rake_tasks!(:compile)
    end

    desc "package", "Package the gem and its extension"
    def package
      ENV["RUBY_CC_VERSION"] ||= compilation_task.ruby_cc_version

      run_rake_tasks!(:cross, :native, :gem)
    end

    desc "clean", "Cleanup compilation artifacts."
    def clean
      run_rake_tasks!(:clean)
    end

    desc "clobber", "Clobber compilation artifacts and binaries."
    def clobber
      run_rake_tasks!(:clobber)
    end

    desc "ci_template", "Generate CI template files"
    method_option "rubies", type: :array, required: true, desc: "The Ruby version you want to test your gem on."
    method_option "os", type: :array, required: true, desc: "The operating systems you want to test your gem on."
    def ci_template
      directory(".github")
    end

    desc "release", "Release the gem with precompiled binaries"
    method_option "glob", type: :string, required: true, desc: "Release all the gems matching the glob"
    def release
      Dir.glob(options[:glob]).each do |file|
        pathname = Pathname(file)
        next if pathname.directory? || pathname.extname != ".gem"

        system("gem push #{file}", exception: true)
      end
    end

    desc "print_ruby_cc_version", "Output the cross compile ruby version needed for the gem."
    def print_ruby_cc_version
      print compilation_task.ruby_cc_version
    end

    private

    def run_rake_tasks!(*tasks)
      all_tasks = tasks.join(" ")
      rakelibdir = File.expand_path("tasks", __dir__)
      load_paths = Gem.loaded_specs["rake-compiler"].full_require_paths.join(":")

      system("bundle exec rake #{all_tasks} -I#{load_paths} -R#{rakelibdir}", exception: true)
    end

    def compilation_task
      @compilation_task ||= CompilationTasks.new(false, options[:gemspec])
    end
  end
end
