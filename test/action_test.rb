# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
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

    def test_install_step_reads_the_cibuildgem_version_from_the_environment
      assert_equal("${{ inputs.version }}", install_step.dig("env", "CIBUILDGEM_VERSION"))
      assert_equal(%(gem install cibuildgem -v "$CIBUILDGEM_VERSION"), version_branch_script("1.2.3"))
    end

    def test_the_version_input_reaches_gem_install_as_a_single_argument
      hostile_version = nil
      argv = nil

      Dir.mktmpdir do |dir|
        marker = File.join(dir, "injected")
        argv_log = File.join(dir, "argv")
        hostile_version = "$(touch #{marker})"

        system(
          { "PATH" => "#{fake_gem_bin(dir, argv_log)}:#{ENV["PATH"]}", "CIBUILDGEM_VERSION" => hostile_version },
          "bash",
          "-c",
          version_branch_script(hostile_version),
          out: File::NULL,
          err: File::NULL,
        )
        refute_path_exists(marker, "the version input was evaluated as shell syntax instead of passed as data")

        argv = File.readlines(argv_log, chomp: true)
      end

      assert_equal(["install", "cibuildgem", "-v", hostile_version], argv)
    end

    private

    def fake_gem_bin(dir, argv_log)
      bin = File.join(dir, "bin")
      FileUtils.mkdir_p(bin)
      File.write(File.join(bin, "gem"), <<~SH)
        #!/usr/bin/env bash
        printf '%s\\n' "$@" > #{argv_log}
      SH
      FileUtils.chmod(0o755, File.join(bin, "gem"))

      bin
    end

    def steps
      YAML.safe_load_file(ACTION_PATH).dig("runs", "steps")
    end

    def install_step
      steps.fetch(0).tap { |step| assert_equal("Install cibuildgem", step["name"]) }
    end

    # The `version` branch of the install step's `case()` expression, rendered as the shell script the runner
    # would produce for `version`. Understands a literal command, which is the safe shape, and a `format()`
    # call interpolating the input, which is the shape these tests exist to reject.
    def version_branch_script(version)
      branch = install_step.fetch("run")[/inputs\.version != null,\s*(.+?),\s*'[^']*'\s*\)/m, 1]
      refute_nil(branch, "no `version` branch found in the install step")

      case branch
      when /\A'(.*)'\z/m then Regexp.last_match(1)
      when /\Aformat\('(.*)',\s*inputs\.version\)\z/m then Regexp.last_match(1).sub("{0}", version)
      else flunk("cannot tell what the install step runs when `version` is set: #{branch}")
      end
    end

    def github_script_steps
      matching = steps.select { |step| step["uses"].to_s.start_with?("actions/github-script") }

      refute_empty(matching)
      matching
    end
  end
end
