# frozen_string_literal: true

require "test_helper"

module EasyCompile
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
      workflow_path = "test/fixtures/dummy_gem/.github/workflows/easy-compile.yaml"

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
      workflow_path = "test/fixtures/dummy_gem/.github/workflows/easy-compile.yaml"

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

      assert_equal("3.4.6:3.3.8:3.2.8", out)
    end
  end
end
