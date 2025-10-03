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
        ext.platform = strip_darwin_versioning(ext) if darwin?
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
      makefile_task = Rake::Task.tasks.find { |task| task.name =~ /Makefile/ }

      makefile_task.enhance do
        makefile_content = File.read(makefile_task.name)
        makefile_content.sub!(/(LIBRUBYARG_SHARED = )(?:-l\$\(RUBY_SO_NAME\))(.*)/, '\1\2')

        File.write(makefile_task.name, makefile_content)
      end
    end

    def strip_darwin_versioning(ext)
      platform = ext.platform.sub(/(-darwin)\d+/, '\1')
      Rake::Task.define_task(native: "native:#{platform}")
      Rake::Task.define_task(compile: "native:#{platform}")

      platform
    end
  end
end
