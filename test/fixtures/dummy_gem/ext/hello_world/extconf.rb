# frozen_string_literal: true

require "mkmf"

$LDFLAGS << " -s -pipe" if RUBY_PLATFORM !~ /darwin/

create_makefile("hello_world")
