# frozen_string_literal: true

module EasyCompile
  module RubySeries
    extend self

    def latest_version_for_requirements(requirements)
      latest_rubies.find do |ruby_version|
        requirements.satisfied_by?(ruby_version)
      end
    end

    # Get the minimum Ruby version to run the compilation. Getting the minimum Ruby
    # version allows ruby/setup-ruby to download the right MSYS2 toolchain and get the
    # right GCC version. GCC 15.1 is incompatible with Ruby 3.0 and 3.1.
    def runtime_version_for_compilation(requirements)
      latest_rubies.reverse.find do |ruby_version|
        requirements.satisfied_by?(ruby_version)
      end
    end

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
      ]
    end

    def latest_rubies
      [
        Gem::Version.new("3.4.7"),
        Gem::Version.new("3.3.9"),
        Gem::Version.new("3.2.9"),
        Gem::Version.new("3.1.7"),
      ]
    end
  end
end
