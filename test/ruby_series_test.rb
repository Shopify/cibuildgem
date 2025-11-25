# frozen_string_literal: true

require "test_helper"

module Cibuildgem
  class RubySeriesTest < Minitest::Test
    def test_latest_version_for_requirements
      requirements = Gem::Requirement.new("~> 3.4")

      assert_equal("3.4.7", RubySeries.latest_version_for_requirements(requirements).to_s)
    end

    def test_latest_version_for_requirements_bis
      requirements = Gem::Requirement.new("> 3")

      assert_equal("3.4.7", RubySeries.latest_version_for_requirements(requirements).to_s)
    end

    def test_latest_version_for_requirements_multiple
      requirements = Gem::Requirement.new(">= 3.3", "< 3.4")

      assert_equal("3.3.9", RubySeries.latest_version_for_requirements(requirements).to_s)
    end

    def test_runtime_version_for_compilation
      requirements = Gem::Requirement.new("~> 3.4")

      assert_equal("3.4.7", RubySeries.runtime_version_for_compilation(requirements).to_s)
    end

    def test_latest_version_for_compilation_multiple
      requirements = Gem::Requirement.new("> 3")

      assert_equal("3.1.7", RubySeries.runtime_version_for_compilation(requirements).to_s)
    end

    def test_versions_to_compile_against
      requirements = Gem::Requirement.new("~> 3.4")

      assert_equal(["3.4.6"], RubySeries.versions_to_compile_against(requirements).map(&:to_s))
    end

    def test_versions_to_compile_against_bis
      requirements = Gem::Requirement.new(">= 3.1")
      expected = ["3.4.6", "3.3.8", "3.2.8", "3.1.6"]

      assert_equal(expected, RubySeries.versions_to_compile_against(requirements).map(&:to_s))
    end

    def test_versions_to_test_against
      requirements = Gem::Requirement.new("~> 3.4")

      assert_equal(["3.4"], RubySeries.versions_to_test_against(requirements).map(&:to_s))
    end

    def test_versions_to_test_against_bis
      requirements = Gem::Requirement.new(">= 3.1")
      expected = ["3.1", "3.2", "3.3", "3.4"]

      assert_equal(expected, RubySeries.versions_to_test_against(requirements).map(&:to_s))
    end
  end
end
