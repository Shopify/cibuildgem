#include "hello_world.h"

VALUE rb_HelloWorld;

static VALUE
hello_world(VALUE self)
{
  return rb_str_new_cstr("Hello world!");
}

void
Init_hello_world(void)
{
  rb_HelloWorld = rb_define_module("HelloWorld");
  rb_define_singleton_method(rb_HelloWorld, "hello_world", hello_world, 0);
}
