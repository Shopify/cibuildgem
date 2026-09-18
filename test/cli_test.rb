# frozen_string_literal: true

require "test_helper"
require "English"
require "open3"
require "tmpdir"

module Cibuildgem
  class CLITest < Minitest::Test
    def setup
      super

      @dllext = RbConfig::MAKEFILE_CONFIG["DLEXT"]
    end

    def teardown
      ENV.delete("RUBY_CC_VERSION")

      super
    end

    def test_compile
      binary_path = "test/fixtures/dummy_gem/lib/hello_world.#{@dllext}"

      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["compile"])
        end
      end

      assert(File.exist?(binary_path))
    ensure
      FileUtils.rm_rf(binary_path)
    end

    def test_clean
      binary_path = "test/fixtures/dummy_gem/tmp/#{RUBY_PLATFORM}/hello_world/#{RUBY_VERSION}/hello_world.#{@dllext}"

      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["compile"])
        end
      end

      assert(File.exist?(binary_path))

      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["clean"])
        end
      end

      refute(File.exist?(binary_path))
    end

    def test_clobber
      pkg_folder = "test/fixtures/dummy_gem/pkg"

      FileUtils.mkdir_p(pkg_folder)

      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["clobber"])
        end
      end

      refute(Dir.exist?(pkg_folder))
    end

    def test_ci_template
      workflow_path = "test/fixtures/dummy_gem/.github/workflows/cibuildgem.yaml"

      expected_workflow = File.read("test/fixtures/expected_github_workflow.yml")
      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["ci_template"])
        end
      end

      assert(File.exist?(workflow_path))
      assert_equal(expected_workflow, File.read(workflow_path))
    ensure
      FileUtils.rm_rf("test/fixtures/dummy_gem/.github")
    end

    def test_ci_template_when_passed_a_working_directory
      workflow_path = "test/fixtures/dummy_gem/.github/workflows/cibuildgem.yaml"

      expected_workflow = File.read("test/fixtures/expected_github_workflow_working_dir.yml")
      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["ci_template", "--working-directory", "test/fixtures/date"])
        end
      end

      assert(File.exist?(workflow_path))
      assert_equal(expected_workflow, File.read(workflow_path))
    ensure
      FileUtils.rm_rf("test/fixtures/dummy_gem/.github")
    end

    def test_ci_template_when_passed_a_test_command
      workflow_path = "test/fixtures/dummy_gem/.github/workflows/cibuildgem.yaml"

      expected_workflow = File.read("test/fixtures/expected_github_workflow_test_command.yml")
      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["ci_template", "--test-command", "bundle exec something"])
        end
      end

      assert(File.exist?(workflow_path))
      assert_equal(expected_workflow, File.read(workflow_path))
    ensure
      FileUtils.rm_rf("test/fixtures/dummy_gem/.github")
    end

    def test_ci_template_when_passed_a_test_command_and_workdir
      workflow_path = "test/fixtures/dummy_gem/.github/workflows/cibuildgem.yaml"

      expected_workflow = File.read("test/fixtures/expected_github_workflow_test_and_workdir.yml")
      Dir.chdir("test/fixtures/dummy_gem") do
        capture_subprocess_io do
          CLI.start(["ci_template", "--test-command", "bundle exec something", "--working-directory", "foo/bar"])
        end
      end

      assert(File.exist?(workflow_path))
      assert_equal(expected_workflow, File.read(workflow_path))
    ensure
      FileUtils.rm_rf("test/fixtures/dummy_gem/.github")
    end

    def test_release_succeeds
      FileUtils.touch("tmp/foo.gem")
      FileUtils.touch("tmp/bar.gem")
      FileUtils.touch("tmp/some_file")

      status = Struct.new(:success?)
      gem_pushed = []
      callable = proc do |*command|
        gem_pushed << command

        ["", status.new(true)]
      end

      Open3.stub(:capture2e, callable) do
        CLI.start(["release", "--glob", "tmp/*"])
      end

      assert_equal([["gem", "push", "tmp/bar.gem"], ["gem", "push", "tmp/foo.gem"]], gem_pushed.sort)
    ensure
      FileUtils.rm_rf("tmp/foo.gem")
      FileUtils.rm_rf("tmp/bar.gem")
      FileUtils.rm_rf("tmp/some_file")
    end

    def test_release_when_gem_was_already_pushed
      FileUtils.touch("tmp/foo.gem")
      FileUtils.touch("tmp/bar.gem")
      FileUtils.touch("tmp/some_file")

      status = Struct.new(:success?)
      gem_pushed = []
      callable = proc do |*command|
        gem_pushed << command

        if command == ["gem", "push", "tmp/bar.gem"]
          ["Repushing of gem versions is not allowed", status.new(false)]
        else
          ["", status.new(true)]
        end
      end

      Open3.stub(:capture2e, callable) do
        out, _ = capture_subprocess_io do
          CLI.start(["release", "--glob", "tmp/*"])
        end

        assert_equal("Gem tmp/bar.gem already exists on RubyGems.org, skipping...\n", out)
      end

      assert_equal([["gem", "push", "tmp/bar.gem"], ["gem", "push", "tmp/foo.gem"]], gem_pushed.sort)
    ensure
      FileUtils.rm_rf("tmp/foo.gem")
      FileUtils.rm_rf("tmp/bar.gem")
      FileUtils.rm_rf("tmp/some_file")
    end

    def test_release_fails
      FileUtils.touch("tmp/foo.gem")
      FileUtils.touch("tmp/bar.gem")
      FileUtils.touch("tmp/some_file")

      status = Struct.new(:success?)
      callable = proc do
        ["Something went wrong", status.new(false)]
      end

      Open3.stub(:capture2e, callable) do
        assert_raises(RuntimeError) do
          CLI.start(["release", "--glob", "tmp/*"])
        end
      end
    ensure
      FileUtils.rm_rf("tmp/foo.gem")
      FileUtils.rm_rf("tmp/bar.gem")
      FileUtils.rm_rf("tmp/some_file")
    end

    def test_release_refuses_a_filename_that_is_not_a_plain_gem_name
      with_fake_gem_executable do |argv_log|
        FileUtils.touch("pkg/hello$(touch injected).gem")

        error = assert_raises(RuntimeError) do
          CLI.start(["release", "--glob", "pkg/*"])
        end

        assert_match("hello$(touch injected).gem", error.message)
        refute(File.exist?("injected"), "the filename was evaluated by a shell")
        refute(File.exist?(argv_log), "the file was handed to `gem push` instead of being refused")
      end
    end

    def test_release_pushes_a_plain_gem_name_without_a_shell
      with_fake_gem_executable do |argv_log|
        FileUtils.touch("pkg/hello_world-1.2.3-x86_64-linux.gem")

        CLI.start(["release", "--glob", "pkg/*"])

        assert_equal(["push", "pkg/hello_world-1.2.3-x86_64-linux.gem"], File.readlines(argv_log, chomp: true))
      end
    end

    def test_print_ruby_cc_version
      out, _ = capture_subprocess_io do
        Dir.chdir("test/fixtures/dummy_gem") do
          CLI.start(["print_ruby_cc_version"])
        end
      end

      assert_equal("4.0.0:3.4.6:3.3.8:3.2.8:3.1.6", out)
    end

    def test_print_ruby_cc_version_env_has_precedence
      ENV["RUBY_CC_VERSION"] = "3.1:3.2"

      out, _ = capture_subprocess_io do
        Dir.chdir("test/fixtures/dummy_gem") do
          CLI.start(["print_ruby_cc_version"])
        end
      end

      assert_equal("3.1:3.2", out)
    ensure
      ENV.delete("RUBY_CC_VERSION")
    end

    def test_when_cli_runs_in_project_with_no_gemspec
      out = nil

      Dir.chdir("lib") do
        out, _ = capture_subprocess_io do
          raise_instead_of_exit do
            CLI.start(["print_ruby_cc_version"])
          end
        end
      end

      assert_equal(<<~MSG, out)
        Couldn't find a gemspec in the current directory.
        Make sure to run any cibuildgem commands in the root of your gem folder.
      MSG
    end

    def test_when_cli_runs_in_project_with_no_native_extension
      out, _ = capture_subprocess_io do
        raise_instead_of_exit do
          CLI.start(["print_ruby_cc_version"])
        end
      end

      assert_equal(<<~MSG, out)
        Your gem has no native extention defined in its gemspec.
        This tool can't be used on pure Ruby gems.
      MSG
    end

    def test_cli_test_command_when_a_test_rake_task_is_defined
      out = nil

      Dir.chdir("test/fixtures/test_task_defined") do
        out, _ = capture_subprocess_io do
          CLI.start(["test"])
        end
      end

      assert_equal("The test task was called.", out)
    end

    def test_cli_test_command_when_a_spec_rake_task_is_defined
      out = nil

      Dir.chdir("test/fixtures/spec_task_defined") do
        out, _ = capture_subprocess_io do
          CLI.start(["test"])
        end
      end

      assert_equal("The spec task was called.", out)
    end

    def test_cli_test_command_when_no_test_or_spec_rake_task_is_defined
      Dir.chdir("test/fixtures/no_test_task_defined") do
        capture_subprocess_io do
          assert_raises(RuntimeError) do
            CLI.start(["test"])
          end
        end
      end
    end

    def test_package_when_a_rakefile_defines_an_extension_task
      Dir.chdir("test/fixtures/with_ext") do
        CLI.start(["package"])
      end

      assert_predicate($CHILD_STATUS, :success?)
    end

    def test_keep_the_extension_task_config_defined_by_the_gem
      Dir.chdir("test/fixtures/with_configured_ext") do
        cli = CLI.new

        out, _ = capture_subprocess_io do
          cli.send(:run_rake_tasks!, :foo)
        end

        assert_equal("foo bar", out)
      end
    end

    def test_run_rake_tasks_builds_an_argv_list_rather_than_a_command_string
      cli = CLI.new
      command = nil
      recorder = ->(*args, **_kwargs) do
        command = args

        true
      end

      cli.stub(:system, recorder) do
        cli.send(:run_rake_tasks!, "cibuildgem:setup", :compile)
      end

      _env, *argv = command

      assert_equal(["bundle", "exec"], argv.first(2))
      assert_includes(argv, "cibuildgem:setup")
      assert_includes(argv, "compile")
    end

    private

    # Runs the block in a scratch directory holding an empty `pkg/`, with a `gem` on PATH that records its
    # arguments in the file whose path is yielded. Nothing is stubbed, so the release path resolves and
    # executes a real subprocess the way it does on a release runner.
    def with_fake_gem_executable(&block)
      original_path = ENV["PATH"]

      Dir.mktmpdir do |dir|
        argv_log = File.join(dir, "argv")
        fake_bin = File.join(dir, "bin")

        FileUtils.mkdir_p(fake_bin)
        File.write(File.join(fake_bin, "gem"), <<~SH)
          #!/bin/sh
          printf '%s\\n' "$@" > #{argv_log}
        SH
        FileUtils.chmod(0o755, File.join(fake_bin, "gem"))
        ENV["PATH"] = [fake_bin, original_path].join(File::PATH_SEPARATOR)

        Dir.chdir(dir) do
          FileUtils.mkdir_p("pkg")

          block.call(argv_log)
        end
      end
    ensure
      ENV["PATH"] = original_path
    end

    def raise_instead_of_exit(&block)
      Kernel.stub(:exit, ->(_) { raise }) do
        assert_raises(StandardError) do
          block.call
        end
      end
    end
  end
end
