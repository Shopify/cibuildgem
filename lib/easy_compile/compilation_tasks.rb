# frozen_string_literal: true

require "bundler"
require "rubygems/package_task"
require "rake/extensiontask"

module EasyCompile
  class CompilationTasks
    attr_reader :gemspec, :native, :create_packaging_task, :extension_task
    attr_accessor :binary_name

    def initialize(create_packaging_task = false, gemspec = nil)
      @gemspec  = Bundler.load_gemspec(gemspec || find_gemspec)
      verify_gemspec!

      @create_packaging_task = create_packaging_task
    end

    def setup
      with_mkmf_monkey_patch do
        gemspec.extensions.each do |path|
          define_task(path)
        end
      end

      setup_packaging if create_packaging_task
    end

    def ruby_cc_version
      required_ruby_version = @gemspec.required_ruby_version
      selected_rubies = RubySeries.versions_to_compile_against(required_ruby_version)

      selected_rubies.map(&:to_s).join(":")
    end

    def normalized_platform
      platform = RUBY_PLATFORM

      if darwin?
        RUBY_PLATFORM.sub(/(.*-darwin)\d+/, '\1')
      elsif win_platform?
        RUBY_PLATFORM.sub(/mingw32/, 'mingw-ucrt')
      else
        platform
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

      @extension_task = Rake::ExtensionTask.new do |ext|
        ext.name = File.basename(binary_name)
        ext.config_script = File.basename(path)
        ext.ext_dir = File.dirname(path)
        ext.lib_dir = binary_lib_dir if binary_lib_dir
        ext.gem_spec = gemspec
        ext.cross_platform = normalized_platform
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

    def win_platform?
      Gem.win_platform?
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

    def find_gemspec(glob = "*.gemspec")
      gemspec = Dir.glob(glob).sort.first
      return gemspec if gemspec

      raise GemspecError, <<~EOM
        Couldn't find a gemspec in the current directory.
        Make sure to run any easy_compile commands in the root of your gem folder.
      EOM
    end

    def verify_gemspec!
      return if gemspec.extensions.any?

      raise GemspecError, <<~EOM
        Your gem has no native extention defined in its gemspec.
        This tool can't be used on pure Ruby gems.
      EOM
    end
  end
end
