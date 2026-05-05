# frozen_string_literal: true

require "test_helper"
require "rake_compiler_dock"

module Cibuildgem
  class ContainerPackagerTest < Minitest::Test
    def setup
      super

      @repo_root = File.expand_path("..", __dir__)
      @fixture_path = File.join(@repo_root, "test/fixtures/date")
      @original_source_path = ENV["CIBUILDGEM_SOURCE_PATH"]
      @original_version = ENV["CIBUILDGEM_VERSION"]
      ENV["CIBUILDGEM_SOURCE_PATH"] = @repo_root
      ENV.delete("CIBUILDGEM_VERSION")
    end

    def teardown
      ENV["CIBUILDGEM_SOURCE_PATH"] = @original_source_path
      ENV["CIBUILDGEM_VERSION"] = @original_version

      super
    end

    def test_package_runs_in_rake_compiler_dock_using_the_bind_mount
      command, options = capture_rake_compiler_dock_invocation do
        ContainerPackager.new(working_directory: @fixture_path, container_image: "custom:image").package
      end

      assert_equal("custom:image", options[:image])
      assert_equal(@fixture_path, options[:mountdir])
      assert_equal(@fixture_path, options[:workdir])
      assert_equal("4.0.2", options[:ruby])

      assert_includes(
        options[:options],
        "--rm",
        "expected --rm flag so containers don't pile up between matrix jobs",
      )

      mount_flag_index = options[:options].index("-v")
      assert(mount_flag_index, "expected a -v mount flag for the host-built gem")
      assert_match(%r{:/opt/cibuildgem-source:ro,z\z}, options[:options][mount_flag_index + 1])

      assert_includes(command, "gem install --no-document /opt/cibuildgem-source/cibuildgem-")
      refute_includes(command, "gem build cibuildgem.gemspec")
      refute_includes(command, "cp -R")
      assert_includes(command, 'BUNDLE_PATH="$HOME/.cibuildgem-bundle"')
      assert_includes(command, "bundle install --jobs=4 --retry=3")
      assert_includes(command, "export RUBY_CC_VERSION=")
      assert_includes(command, "cibuildgem package")
    end

    def test_package_omits_bundle_install_when_no_bundle_is_requested
      command, _ = capture_rake_compiler_dock_invocation do
        ContainerPackager.new(working_directory: @fixture_path).run(command: "echo hi")
      end

      refute_includes(command, "bundle install")
      assert_includes(command, "echo hi")
    end

    def test_package_raises_for_non_linux_targets
      packager = ContainerPackager.new(working_directory: @fixture_path)

      packager.stub(:linux_target?, false) do
        assert_raises(ContainerError) { packager.package }
      end
    end

    def test_package_passes_through_musl_and_aarch64_platforms_to_rake_compiler_dock
      [
        "x86_64-linux-musl",
        "aarch64-linux-musl",
        "aarch64-linux-gnu",
      ].each do |platform|
        packager = ContainerPackager.new(working_directory: @fixture_path)
        packager.send(:compilation_task).stub(:normalized_platform, platform) do
          _, options = capture_rake_compiler_dock_invocation { packager.package }

          assert_equal(platform, options[:platform], "expected #{platform} to be forwarded to rake-compiler-dock")
        end
      end
    end

    def test_load_source_gemspec_resolves_files_against_source_path_not_pwd
      packager = ContainerPackager.new(working_directory: @fixture_path)

      Dir.chdir(@fixture_path) do
        gemspec = packager.send(:load_source_gemspec)

        assert_equal("cibuildgem", gemspec.name)
        assert_includes(gemspec.files, "lib/cibuildgem.rb")
        refute(gemspec.files.any? { |f| f.start_with?("lib/date") }, "must not pick up files from the working_directory")
      end
    end

    def test_run_installs_the_requested_cibuildgem_version_and_skips_host_build
      ENV["CIBUILDGEM_VERSION"] = "9.9.9"

      command, options = capture_rake_compiler_dock_invocation do
        ContainerPackager.new(working_directory: @fixture_path, container_image: "custom:image")
          .run(command: "echo ok")
      end

      assert_equal("custom:image", options[:image])
      refute_includes(options[:options], "-v")
      assert_includes(command, "gem install --no-document cibuildgem -v 9.9.9")
      refute_includes(command, "gem build")
      assert_includes(command, "echo ok")
    end

    private

    def capture_rake_compiler_dock_invocation(&block)
      command = nil
      options = nil
      capture = lambda do |cmd, args|
        command = cmd
        options = args
      end

      RakeCompilerDock.stub(:sh, capture, &block)

      [command, options]
    end
  end
end
