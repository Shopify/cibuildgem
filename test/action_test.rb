# frozen_string_literal: true

require "test_helper"
require "yaml"

module Cibuildgem
  class ActionTest < Minitest::Test
    ACTION_PATH = File.expand_path("../.github/actions/cibuildgem/action.yml", __dir__)

    def test_github_script_steps_do_not_interpolate_workflow_expressions
      github_script_steps.each do |step|
        script = step.dig("with", "script")

        refute_match(
          /\$\{\{/,
          script,
          "Step #{step["name"].inspect} interpolates a workflow expression into evaluated " \
            "JavaScript. Pass the value through `env:` and read it from `process.env` instead.",
        )
      end
    end

    def test_setup_rake_compiler_reads_the_working_directory_from_the_environment
      step = github_script_steps.fetch(0)

      assert_equal("${{ inputs.working-directory }}", step.dig("env", "WORKING_DIRECTORY"))
      assert_includes(step.dig("with", "script"), "run(process.env.WORKING_DIRECTORY)")
    end

    private

    def github_script_steps
      steps = YAML.safe_load_file(ACTION_PATH).dig("runs", "steps")
      matching = steps.select { |step| step["uses"].to_s.start_with?("actions/github-script") }

      refute_empty(matching)
      matching
    end
  end
end
