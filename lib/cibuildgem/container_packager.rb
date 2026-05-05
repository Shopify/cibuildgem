# frozen_string_literal: true

require "digest"
require "fileutils"
require "pathname"
require "shellwords"
require "tmpdir"
require "rake_compiler_dock"
require "rubygems/user_interaction"

module Cibuildgem
  class ContainerPackager
    CONTAINER_SOURCE_PATH = "/opt/cibuildgem-source"
    HOST_BUILD_CACHE_DIRNAME = "cibuildgem-host-build-cache"

    def initialize(working_directory: Dir.pwd, gemspec: nil, container_image: nil, version: nil)
      @working_directory = File.expand_path(working_directory)
      @gemspec_path = resolve_gemspec_path(gemspec)
      @container_image = normalize_string(container_image || ENV["CIBUILDGEM_CONTAINER_IMAGE"])
      @version = normalize_string(version || ENV["CIBUILDGEM_VERSION"])
      @source_path = resolve_source_path
      @compilation_task = with_working_directory do
        CompilationTasks.new(false, @gemspec_path)
      end
    end

    def package
      run(command: package_command, prepare_bundle: true)
    end

    def run(command:, prepare_bundle: false)
      raise ContainerError, "Container execution is only supported for Linux targets." unless linux_target?
      raise ContainerError, "No container command was provided." if normalize_string(command).nil?

      with_host_built_cibuildgem_gem do |host_gem_path|
        RakeCompilerDock.sh(
          container_command(command, prepare_bundle: prepare_bundle, host_gem_path: host_gem_path),
          rake_compiler_dock_options(host_gem_path),
        )
      end
    end

    private

    attr_reader :working_directory, :gemspec_path, :container_image, :version, :source_path, :compilation_task

    def linux_target?
      Gem::Platform.new(compilation_task.normalized_platform).os == "linux"
    end

    def rake_compiler_dock_options(host_gem_path)
      options = {
        platform: compilation_task.normalized_platform,
        ruby: container_ruby_version,
        mountdir: working_directory,
        workdir: working_directory,
      }
      options[:image] = container_image if container_image

      docker_options = ["--rm", "-i"]
      docker_options << "-t" if $stdin.tty?
      if host_gem_path
        # `:z` is needed for SELinux/podman; ignored elsewhere
        docker_options.push("-v", "#{File.dirname(host_gem_path)}:#{CONTAINER_SOURCE_PATH}:ro,z")
      end
      options[:options] = docker_options

      options
    end

    def container_command(command, prepare_bundle:, host_gem_path:)
      commands = [
        "set -euo pipefail",
        install_cibuildgem_command(host_gem_path),
      ]
      commands << bundle_install_command if prepare_bundle
      commands << command

      commands.join("\n")
    end

    # `bundle check` is unreliable here (lockfile rarely lists the runner's platform), so install unconditionally.
    def bundle_install_command
      <<~SH.strip
        if [ -f Gemfile ]; then
          export BUNDLE_PATH="$HOME/.cibuildgem-bundle"
          bundle install --jobs=4 --retry=3
        fi
      SH
    end

    def install_cibuildgem_command(host_gem_path)
      if version
        "gem install --no-document cibuildgem -v #{version.shellescape}"
      elsif host_gem_path
        gem_in_container = "#{CONTAINER_SOURCE_PATH}/#{File.basename(host_gem_path)}"
        "gem install --no-document #{gem_in_container.shellescape}"
      else
        raise ContainerError, <<~MSG
          Can't figure out which cibuildgem to install in the container.
          Set CIBUILDGEM_SOURCE_PATH to a checkout, or pass --version / CIBUILDGEM_VERSION.
        MSG
      end
    end

    def package_command
      [
        "export RUBY_CC_VERSION=#{RakeCompilerDock.ruby_cc_version(compilation_task.gemspec.required_ruby_version).shellescape}",
        "cibuildgem package#{package_options}",
      ].join("\n")
    end

    def package_options
      return "" unless gemspec_path

      relative_gemspec = Pathname.new(gemspec_path).relative_path_from(Pathname.new(working_directory)).to_s
      " --gemspec #{relative_gemspec.shellescape}"
    end

    def container_ruby_version
      RakeCompilerDock.ruby_cc_version(compilation_task.gemspec.required_ruby_version).split(":").first
    end

    def resolve_gemspec_path(gemspec)
      return unless gemspec

      File.expand_path(gemspec, working_directory)
    end

    def resolve_source_path
      candidates = [
        ENV["CIBUILDGEM_SOURCE_PATH"],
        Gem.loaded_specs["cibuildgem"]&.full_gem_path,
        File.expand_path("../..", __dir__),
      ]

      candidates.each do |candidate|
        path = normalize_string(candidate)
        next unless path

        expanded = File.expand_path(path)
        return expanded if File.file?(File.join(expanded, "cibuildgem.gemspec"))
      end

      nil
    end

    def normalize_string(value)
      return if value.nil?

      normalized = value.strip
      normalized.empty? ? nil : normalized
    end

    def with_working_directory(&block)
      Dir.chdir(working_directory, &block)
    end

    def with_host_built_cibuildgem_gem
      return yield(nil) if version || source_path.nil?

      gem_path = cached_or_built_gem_path
      yield(gem_path)
    end

    def cached_or_built_gem_path
      gemspec = load_source_gemspec
      cache_dir = File.join(Dir.tmpdir, HOST_BUILD_CACHE_DIRNAME)
      FileUtils.mkdir_p(cache_dir)

      filename = "cibuildgem-#{gemspec.version}-#{source_fingerprint(gemspec)}.gem"
      cached_path = File.join(cache_dir, filename)
      return cached_path if File.file?(cached_path)

      build_cibuildgem_gem(gemspec, cached_path)
      cached_path
    end

    def load_source_gemspec
      gemspec = Gem::Specification.load(File.join(source_path, "cibuildgem.gemspec"))
      raise ContainerError, "Unable to load cibuildgem.gemspec from #{source_path}." unless gemspec

      gemspec
    end

    def source_fingerprint(gemspec)
      digest = Digest::SHA256.new
      digest.update(File.binread(File.join(source_path, "cibuildgem.gemspec")))

      gemspec.files.sort.each do |relative|
        absolute = File.join(source_path, relative)
        next unless File.file?(absolute)

        digest.update(relative)
        digest.update("\0")
        digest.update(File.binread(absolute))
      end

      digest.hexdigest[0, 16]
    end

    def build_cibuildgem_gem(gemspec, destination_path)
      Dir.mktmpdir("cibuildgem-host-build-") do |tmp|
        built_gem_filename = Dir.chdir(source_path) do
          Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
            Gem::Package.build(gemspec)
          end
        end

        built_path = File.join(source_path, built_gem_filename)
        scratch_path = File.join(tmp, built_gem_filename)
        FileUtils.mv(built_path, scratch_path)
        FileUtils.mv(scratch_path, destination_path)
      end
    end
  end
end
