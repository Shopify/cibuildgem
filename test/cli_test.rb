# frozen_string_literal: true

require "test_helper"
require "English"

module Cibuildgem
  class CLITest < Minitest::Test
    def setup
      super

      @dllext = RbConfig::MAKEFILE_CONFIG["DLEXT"]
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

    def test_release
      FileUtils.touch("tmp/foo.gem")
      FileUtils.touch("tmp/bar.gem")
      FileUtils.touch("tmp/some_file")

      gem_pushed = []

      Kernel.stub(:system, ->(gem, _) { gem_pushed << gem }) do
        CLI.start(["release", "--glob", "tmp/*"])
      end

      assert_equal(["gem push tmp/bar.gem", "gem push tmp/foo.gem"], gem_pushed.sort)
    ensure
      FileUtils.rm_rf("tmp/foo.gem")
      FileUtils.rm_rf("tmp/bar.gem")
      FileUtils.rm_rf("tmp/some_file")
    end

    def test_print_ruby_cc_version
      out, _ = capture_subprocess_io do
        Dir.chdir("test/fixtures/dummy_gem") do
          CLI.start(["print_ruby_cc_version"])
        end
      end

      assert_equal("3.4.6:3.3.8:3.2.8:3.1.6", out)
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

    private

    def raise_instead_of_exit(&block)
      Kernel.stub(:exit, ->(_) { raise }) do
        assert_raises(StandardError) do
          block.call
        end
      end
    end
  end
end
