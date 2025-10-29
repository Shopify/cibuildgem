# frozen_string_literal: true

require "mkmf"

$LDFLAGS << " -s -pipe"

create_makefile("hello_world")
