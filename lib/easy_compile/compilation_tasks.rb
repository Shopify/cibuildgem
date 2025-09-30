# frozen_string_literal: true

require "bundler"
require "rubygems/gemspec_helpers"
require "rake/extensiontask"

module EasyCompile
  class CompilationTasks
    include Gem::GemspecHelpers

    attr_reader :gemspec, :native
    attr_accessor :binary_name

    def initialize(gemspec = nil, native = false)
      @gemspec  = Bundler.load_gemspec(gemspec || find_gemspec)
      @native = native
    end

    def setup
      with_mkmf_monkey_patch do
        gemspec.extensions.each do |path|
          define_task(path)
        end
      end
    end

    private

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
        ext.gem_spec = @gemspec if native
      end
    ensure
      self.binary_name = nil
    end

    def binary_lib_dir
      dir = File.dirname(binary_name)
      return if dir == "."

      gemspec.raw_require_paths.first + "/#{dir}"
    end
  end
end
