# frozen_string_literal: true

require "bundler"
require "rubygems/gemspec_helpers"
require "rubygems/package_task"
require "rake/extensiontask"

module EasyCompile
  class CompilationTasks
    include Gem::GemspecHelpers

    attr_reader :gemspec, :native
    attr_accessor :binary_name

    def initialize(gemspec, create_packaging_task)
      @gemspec  = Bundler.load_gemspec(gemspec || find_gemspec)

      setup_packaging if create_packaging_task
    end

    def setup
      with_mkmf_monkey_patch do
        gemspec.extensions.each do |path|
          define_task(path)
        end
      end
    end

    def ruby_cc_version
      required_ruby_version = @gemspec.required_ruby_version

      selected_rubies = cross_rubies.select do |ruby_version|
        required_ruby_version.satisfied_by?(ruby_version)
      end

      selected_rubies.map(&:to_s).join(":")
    end

    private

    def setup_packaging
      Gem::PackageTask.new(gemspec) do |pkg|
        pkg.need_zip = true
        pkg.need_tar = true
      end
    end

    def with_mkmf_monkey_patch
      require "mkmf"

      instance = self

      Object.define_method(:create_makefile) do |name, *args|
        instance.binary_name = name
      end

      yield
    ensure
      Object.remove_method(:create_makefile)
    end

    def define_task(path)
      require File.expand_path(path)

      Rake::ExtensionTask.new do |ext|
        ext.name = File.basename(binary_name)
        ext.config_script = File.basename(path)
        ext.ext_dir = File.dirname(path)
        ext.lib_dir = binary_lib_dir if binary_lib_dir
        ext.gem_spec = gemspec
        ext.cross_platform = platform_without_darwin_version
        ext.cross_compile = true
      end

      disable_shared if darwin? && shared_enabled?
    ensure
      self.binary_name = nil
    end

    def binary_lib_dir
      dir = File.dirname(binary_name)
      return if dir == "."

      gemspec.raw_require_paths.first + "/#{dir}"
    end

    def darwin?
      Gem::Platform.local.os == "darwin"
    end

    def shared_enabled?
      RbConfig::CONFIG["ENABLE_SHARED"] == "yes"
    end

    def disable_shared
      makefile_tasks = Rake::Task.tasks.select { |task| task.name =~ /Makefile/ }

      makefile_tasks.each do |task|
        task.enhance do
          makefile_content = File.read(task.name)
          makefile_content.sub!(/(LIBRUBYARG_SHARED = )(?:-l\$\(RUBY_SO_NAME\))(.*)/, '\1\2')

          File.write(task.name, makefile_content)
        end
      end
    end

    def platform_without_darwin_version
      platform = RUBY_PLATFORM
      return platform unless darwin?

      RUBY_PLATFORM.sub(/(.*-darwin)\d+/, '\1')
    end

    def cross_rubies
     versions = [
        "3.3.9",
        "3.2.9",
      ]
     versions.push("3.1.7", "3.0.7") unless Gem.win_platform? # GCC 15 incompatibility on Ruby 3.1 and 3.0 for windows.

     versions.map { |version| Gem::Version.new(version) }
    end
  end
end
