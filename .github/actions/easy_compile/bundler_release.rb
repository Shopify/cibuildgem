# frozen_string_literal: true

require 'bundler'

Bundler.with_clean_env do
  system("easy_compile release")

  exit(0) # TODO Exit status
end
