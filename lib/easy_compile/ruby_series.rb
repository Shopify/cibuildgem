# frozen_string_literal: true

module EasyCompile
  module RubySeries
    extend self

    def latest_version_for_requirements(requirements)
      latest_rubies.find do |ruby_version|
        requirements.satisfied_by?(ruby_version)
      end
    end
    alias_method :runtime_version_for_compilation, :latest_version_for_requirements

    def versions_to_compile_against(requirements)
      cross_rubies.select do |ruby_version|
        requirements.satisfied_by?(ruby_version)
      end
    end

    def versions_to_test_agaist(requirements)
      latest_rubies.select do |ruby_version|
        requirements.satisfied_by?(ruby_version)
      end
    end

    def cross_rubies
      [
        Gem::Version.new("3.4.6"),
        Gem::Version.new("3.3.8"),
        Gem::Version.new("3.2.8"),
        Gem::Version.new("3.1.6"),
        Gem::Version.new("3.0.6"),
      ]
    end

    def latest_rubies
      [
        Gem::Version.new("3.4.7"),
        Gem::Version.new("3.3.9"),
        Gem::Version.new("3.2.9"),
        Gem::Version.new("3.1.7"),
        Gem::Version.new("3.0.7"),
      ]
    end
  end
end
