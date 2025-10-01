# frozen_string_literal: true

require 'bundler'

Bundler.with_clean_env do
  system('easy_compile release --glob "pkg/*"', exception: true)

  exit(0)
end
