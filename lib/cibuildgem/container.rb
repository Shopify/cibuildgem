# frozen_string_literal: true

require "open3"

module Cibuildgem
  module Container
    extend self

    def execute(command, runtime_ruby:)
      dockerfile = File.expand_path("../docker/Dockerfile", __FILE__)
      system("podman image build -t cibuildgem -f #{dockerfile}", exception: true)

      puts ENV["RUNNER_TEMP"]
      # system("podman container run -it -v /Users/edouard/Documents/rubies:/opt/rubies -v /Users/edouard/Documents/config.yml:/root/.rake-compiler/config.yml cibuildgem /bin/bash")
    end

    def cpu
      Gem::Platform.local.cpu
    end
  end
end
