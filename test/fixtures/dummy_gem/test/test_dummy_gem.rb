# frozen_string_literal: true

require "test_helper"

class TestDummyGem < Minitest::Test
  def test_it_returns_hello_world
    assert_equal("Hello world!", HelloWorld.hello_world)
  end
end
