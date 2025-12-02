# frozen_string_literal: true

require "open3"

module Cibuildgem
  module Container
    extend self

    def execute(command, runtime_ruby:)
      dockerfile = File.expand_path("../docker/Dockerfile", __FILE__)
      system("podman image build -t cibuildgem -f #{dockerfile}", exception: true)

      puts "The current directory is: #{Dir.pwd}"
      system("podman container run --rm -it #{volumes_mount} cibuildgem bash -i -c 'cibuildgem package'")
      # system("podman container run --rm -it #{volumes_mount} cibuildgem bash -i -c 'ls -la -R'")
    end

    private

    def volumes_mount
      mounts = [
        "-v #{ENV['RUNNER_TEMP']}/rubies:/opt/cross-rubies",
        "-v #{Dir.home}/.rake-compiler/config.yml:/root/.rake-compiler/config.yml",
        "-v #{Dir.pwd}:/project",
      ]

      mounts.join(" ")
    end
  end
end
