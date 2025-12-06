# frozen_string_literal: true

require "bundler"
require "rubygems/package_task"
require "rake/extensiontask"
require_relative "create_makefile_finder"

module Cibuildgem
  class CompilationTasks
    attr_reader :gemspec, :native, :create_packaging_task, :extension_task

    def initialize(create_packaging_task = false, gemspec = nil)
      @gemspec = Bundler.load_gemspec(gemspec || find_gemspec)
      verify_gemspec!

      @create_packaging_task = create_packaging_task
    end

    def setup
      Rake::ExtensionTask.enable!

      gemspec.extensions.each do |path|
        binary_name = parse_extconf(path)
        define_task(path, binary_name)
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

    def define_task(path, binary_name)
      @extension_task = Rake::ExtensionTask.new do |ext|
        ext.name = File.basename(binary_name)
        ext.config_script = File.basename(path)
        ext.ext_dir = File.dirname(path)
        ext.lib_dir = binary_lib_dir(binary_name) if binary_lib_dir(binary_name)
        ext.gem_spec = gemspec
        ext.cross_platform = normalized_platform
        ext.cross_compile = true
        ext.no_native = true
      end

      disable_shared unless Gem.win_platform?
    end

    def binary_lib_dir(binary_name)
      dir = File.dirname(binary_name)
      return if dir == "."

      gemspec.raw_require_paths.first + "/#{dir}"
    end

    def darwin?
      Gem::Platform.local.os == "darwin"
    end

    def disable_shared
      makefile_tasks = Rake::Task.tasks.select { |task| task.name =~ /Makefile/ }

      makefile_tasks.each do |task|
        task.enhance do
          makefile_content = File.read(task.name)
          makefile_content.match(/LIBRUBYARG_SHARED = (.*)/) do |match|
            shared_flags = match[1].split(" ")
            shared_flags.reject! { |flag| flag == "-l$(RUBY_SO_NAME)" }
            makefile_content.gsub!(/(LIBRUBYARG_SHARED = ).*/, "\\1#{shared_flags.join(" ")}")

            File.write(task.name, makefile_content)
          end
        end
      end
    end

    def find_gemspec(glob = "*.gemspec")
      gemspec = Dir.glob(glob).sort.first
      return gemspec if gemspec

      raise GemspecError, <<~EOM
        Couldn't find a gemspec in the current directory.
        Make sure to run any cibuildgem commands in the root of your gem folder.
      EOM
    end

    def verify_gemspec!
      return if gemspec.extensions.any?

      raise GemspecError, <<~EOM
        Your gem has no native extention defined in its gemspec.
        This tool can't be used on pure Ruby gems.
      EOM
    end

    def parse_extconf(path)
      visitor = CreateMakefileFinder.new
      Prism.parse_file(path).value.accept(visitor)

      visitor.binary_name
    end
  end
end
