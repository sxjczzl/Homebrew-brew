# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop makes sure that a `version` is in the correct format.
      #
      # @api private
      class Version < FormulaCop
        def on_formula_version(node)
          param = parameters(node).first
          return if param.lvar_type?

          offending_node(node)
          version = string_content(param)

          problem "version is set to an empty string" if version.empty?

          problem "version #{version} should not have a leading 'v'" if version.start_with?("v")

          return unless version.match?(/_\d+$/)

          problem "version #{version} should not end with an underline and a number"
        end
      end
    end
  end
end
