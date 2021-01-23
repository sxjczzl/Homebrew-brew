# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `python-internal` dependencies in formulae.
      #
      # @api private
      class DependsOnPythonInternalCop < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, _body_node)
          dep = depends_on?("python-internal")

          return if dep.blank?

          unless tap_style_exception? :depends_on_python_internal_allowlist
            problem "This formula is not allowed to depend on python-internal."
          end

          dep.child_nodes.each do |child_node|
            next if child_node.hash_type? &&
                    child_node.values.first.sym_type? &&
                    child_node.values.first.value == :build

            problem "The python-internal dependency can only be a :build dependency."
          end
        end
      end
    end
  end
end
