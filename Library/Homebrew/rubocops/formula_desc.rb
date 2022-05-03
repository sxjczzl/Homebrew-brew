# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"
require "rubocops/shared/desc_helper"
require "extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `desc` in formulae.
      # See the {DescHelper} module for details of the checks.
      class Desc < FormulaCop
        include DescHelper
        extend AutoCorrector

        def on_formula_class(_class_node)
          @formula_desc = nil
        end

        def on_formula_desc(node)
          # audit_desc also tracks description presence, so defer to class end
          @formula_desc = node
        end

        def on_formula_class_end(class_node)
          @name = @formula_name
          offending_node(class_node)
          audit_desc(:formula, @name, @formula_desc)
        end
      end
    end
  end
end
