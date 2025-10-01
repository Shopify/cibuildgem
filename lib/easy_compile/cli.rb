# frozen_string_literal: true

require "thor"
require "bundler"
require "fileutils"

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
      setup_tasks(options[:gemspec])
      Rake::Task["compile"].invoke

      system "bundle exec rake test"
    end

    desc "package", "Package the gem and its extension"
    def package
      setup_tasks(options[:gemspec], true)
      Rake::Task[:native].invoke

      Rake::Task[:gem].invoke
    end

    desc "clean", "Cleanup compilation artifacts."
    def clean
      setup_tasks(options[:gemspec])

      Rake::Task["clean"].invoke
    end

    desc "clobber", "Clobber compilation artifacts and binaries."
    def clobber
      setup_tasks(options[:gemspec])

      Rake::Task["clobber"].invoke
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

    private

    def setup_tasks(gemspec, native = false)
      tasks = CompilationTasks.new(gemspec, native)

      tasks.setup
    end
  end
end
