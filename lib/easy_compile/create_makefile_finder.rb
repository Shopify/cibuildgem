# frozen_string_literal: true

require "prism"

module EasyCompile
  class CreateMakefileFinder < Prism::Visitor
    attr_reader :binary_name

    def visit_call_node(node)
      super
      looking_for = [:create_makefile, :create_rust_makefile]
      return unless looking_for.include?(node.name)

      @binary_name = node.arguments.child_nodes.first.content
    end
  end
end
