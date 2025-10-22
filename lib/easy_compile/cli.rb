# frozen_string_literal: true

require "thor"
require "rake/extensiontask"

module EasyCompile
  class CLI < Thor
    include Thor::Actions

    source_root(File.expand_path("templates", __dir__))

    def self.exit_on_failure?
      true
    end

    desc "compile", "Compile a gem's native extension."
    long_desc <<~MSG
      This command will read a gem's gemspec file and setup a Rake Compiler task to be executed.
      You need to run this command at the root of the project.

      It's not required for a gem to define a `Rake::ExtensionTask`. However, if such task exists,
      it will be executed as part of the compilation process.

      The Rakefile of the project will be loaded and you may enhance or add other prequisite tasks
      to the compilation.
    MSG
    def compile
      run_rake_tasks!(:compile)
    end

    desc "package", "Compile and package a 'fat gem'.", hide: true
    long_desc <<~MSG
      This command should normally run on CI, using the EasyCompile workflow. It will not work locally unless
      the environment is properly setup.

      Based on a gem's gemspec, create a tailored-made Rake Compiler task to create two gems:
      - A gem with precompiled binary compatible on the platform running the command.
      - A gem without precompiled binary (Ruby platform).

      The gem with precompiled binaries will be packaged with multiple binaries compatible for different
      Ruby ABI (depending on what Ruby version the gem supports).
    MSG
    method_option "gemspec", type: "string", required: false, desc: "The gemspec to use. Defaults to the gemspec from the current working directory."
    def package
      ENV["RUBY_CC_VERSION"] ||= compilation_task.ruby_cc_version

      run_rake_tasks!(:cross, :native, :gem)
    end

    desc "copy_from_staging_to_lib", "Copy the staging binary. For internal usage.", hide: true
    def copy_from_staging_to_lib
      run_rake_tasks!("copy:stage:lib")
    end

    desc "clean", "Cleanup temporary compilation artifacts."
    long_desc <<~MSG
      Cleanup temporary artifacts used for compiling the gem's extension.

      When this command is invoked, the gem's Rakefile will be loaded and you can customize which artifacts
      to cleanup by adding files to the vanilla CLEAN rake list.
    MSG
    def clean
      run_rake_tasks!(:clean)
    end

    desc "clobber", "Remove compiled binaries."
    long_desc <<~MSG
      Remove compiled binaries.

      When this command is invoked, the gem's Rakefile will be loaded and you can customize the list of files
      to remove by adding files to the vanilla CLOBBER rake list.
    MSG
    def clobber
      run_rake_tasks!(:clobber)
    end

    desc "ci_template", "Generate CI template files."
    long_desc <<~MSG
      Generate a GitHub workflow to perform all the steps needed for compiling a gem's extension and packaging its binaries.

      This command needs to run at the root of your project and expects to see a `.gemspec` file. It will read the gemspec
      and determine what Ruby versions needs to be used for precompiling a "fat gem".
    MSG
    method_option "working-directory", type: "string", required: false, desc: "If your gem lives outside of the repository root, specify where."
    method_option "gemspec", type: "string", required: false, desc: "The gemspec to use. If the option is not passed, a gemspec file from the current working directory will be used."
    def ci_template
      # os = ["macos-latest", "macos-15-intel", "ubuntu-latest", "windows-latest"]
      os = ["macos-latest", "ubuntu-latest"] # Just this for now because the CI takes too long otherwise.
      ruby_requirements = compilation_task.gemspec.required_ruby_version
      latest_supported_ruby_version = RubySeries.latest_version_for_requirements(ruby_requirements)
      runtime_version_for_compilation = RubySeries.runtime_version_for_compilation(ruby_requirements)
      ruby_versions_for_testing = RubySeries.versions_to_test_agaist(ruby_requirements).map(&:to_s)

      directory(".github", context: instance_eval("binding"))
    end

    desc "release", "Release the gem with precompiled binaries. For internal usage.", hide: true
    method_option "glob", type: :string, required: true, desc: "Release all the gems matching the glob"
    def release
      Dir.glob(options[:glob]).each do |file|
        pathname = Pathname(file)
        next if pathname.directory? || pathname.extname != ".gem"

        system("gem push #{file}", exception: true)
      end
    end

    desc "print_ruby_cc_version", "Output the cross compile ruby version needed for the gem. For internal usage", hide: true
    method_option "gemspec", type: "string", required: false, desc: "The gemspec to use. If the option is not passed, a gemspec file from the current working directory will be used."
    def print_ruby_cc_version
      print compilation_task.ruby_cc_version
    end

    desc "normalized_platform", "The platform name for compilation purposes", hide: true
    def print_normalized_platform
      print compilation_task.normalized_platform
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
