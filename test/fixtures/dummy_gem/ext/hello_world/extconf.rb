# frozen_string_literal: true

require "mkmf"

$LIBRUBYARG_SHARED = "" if RUBY_PLATFORM =~ /darwin/
create_makefile("hello_world")
