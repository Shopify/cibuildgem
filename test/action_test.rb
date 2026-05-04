# frozen_string_literal: true

require "test_helper"
require "yaml"

module Cibuildgem
  class ActionTest < Minitest::Test
    ACTION_PATH = File.expand_path("../.github/actions/cibuildgem/action.yml", __dir__)

    def test_linux_follow_up_steps_run_in_containers_by_default
      assert_equal(
        "${{ inputs.step == 'test_cross' && runner.os == 'Linux' }}",
        step("Execute cross tests in Linux container").fetch("if"),
      )
      assert_equal(
        "${{ inputs.step == 'install' && runner.os == 'Linux' }}",
        step("Install gems in Linux container").fetch("if"),
      )
      assert_equal(
        "${{ inputs.step == 'test_cross' && runner.os != 'Linux' }}",
        step("Copy staging binary to the libdir").fetch("if"),
      )
      assert_equal(
        "${{ inputs.step == 'install' && runner.os != 'Linux' }}",
        step("Install gems").fetch("if"),
      )
    end

    def test_action_install_step_branches_on_version_and_repository
      install_step_run = step("Install cibuildgem").fetch("run")

      assert_includes(install_step_run, "inputs.version != null, format(")
      assert_includes(install_step_run, "github.repository == 'Shopify/cibuildgem', 'rake install'")
      assert_includes(install_step_run, "'gem install cibuildgem'")
    end

    def test_linux_container_image_input_is_declared
      input = action.fetch("inputs").fetch("linux-container-image")

      refute(input.fetch("required"))
      assert_includes(input.fetch("description"), "rake-compiler-dock")
    end

    def test_every_linux_container_step_passes_the_required_env_vars
      linux_steps = [
        "Package in Linux container",
        "Execute cross tests in Linux container",
        "Install gems in Linux container",
      ]

      linux_steps.each do |name|
        env = step(name).fetch("env")

        assert_equal(
          "${{ inputs.linux-container-image }}",
          env.fetch("CIBUILDGEM_CONTAINER_IMAGE"),
          "#{name}: container image must be plumbed through",
        )
        assert_equal(
          "${{ inputs.version }}",
          env.fetch("CIBUILDGEM_VERSION"),
          "#{name}: version must be plumbed through",
        )
      end
    end

    def test_download_artifact_steps_extract_into_the_working_directory
      ["Download compiled binaries", "Download tarball for platform"].each do |name|
        with = step(name).fetch("with")

        assert_equal(
          "${{ inputs.working-directory }}",
          with.fetch("path"),
          "#{name} must extract artifacts under the gem's working-directory",
        )
      end
    end

    def test_install_gems_step_runs_in_the_working_directory
      assert_equal("${{ inputs.working-directory }}", step("Install gems").fetch("working-directory"))
    end

    def test_execute_the_tests_skips_the_linux_test_cross_path
      assert_includes(
        step("Execute the tests").fetch("if"),
        "!(inputs.step == 'test_cross' && runner.os == 'Linux')",
      )
    end

    private

    def action
      @action ||= YAML.safe_load_file(ACTION_PATH)
    end

    def step(name)
      action.fetch("runs").fetch("steps").find do |step_definition|
        step_definition["name"] == name
      end || flunk("Unable to find action step: #{name}")
    end
  end
end
