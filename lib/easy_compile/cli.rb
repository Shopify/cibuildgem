# frozen_string_literal: true

require "thor"
require "rake/extensiontask"

module EasyCompile
  class CLI < Thor
    include Thor::Actions

    source_root(File.expand_path("templates", __dir__))
    default_command :compile_and_test

    def self.exit_on_failure?
      true
    end

    desc "compile", "Compile a gem's native extension based on its gemspec."
    def compile
      run_rake_tasks!(:compile)
    end

    desc "package", "Package the gem and its extension"
    method_option "gemspec", type: "string", required: false, desc: "The gemspec to use. If the option is not passed, a gemspec file from the current working directory will be used."
    def package
      ENV["RUBY_CC_VERSION"] ||= compilation_task.ruby_cc_version

      run_rake_tasks!(:cross, :native, :gem)
    end

    desc "copy_from_staging_to_lib", "Copy the staging binary"
    def copy_from_staging_to_lib
      run_rake_tasks!("copy:stage:lib")
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
    method_option "working-directory", type: "string", required: false, desc: "If your gem lives outside of the repository root, specifiy where."
    method_option "gemspec", type: "string", required: false, desc: "The gemspec to use. If the option is not passed, a gemspec file from the current working directory will be used."
    def ci_template
      # os = ["macos-latest", "macos-15-intel", "ubuntu-latest", "windows-latest"]
      os = ["macos-latest", "ubuntu-latest"] # Just this for now because the CI takes too long otherwise.
      ruby_requirements = compilation_task.gemspec.required_ruby_version
      latest_supported_ruby_version = RubySeries.latest_version_for_requirements(ruby_requirements)
      ruby_versions_for_testing = RubySeries.versions_to_test_agaist(ruby_requirements).map(&:to_s)

      directory(".github", context: instance_eval("binding"))
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
    method_option "gemspec", type: "string", required: false, desc: "The gemspec to use. If the option is not passed, a gemspec file from the current working directory will be used."
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
