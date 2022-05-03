# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"
require "extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits versioned formulae for `conflicts_with`.
      class Conflicts < FormulaCop
        extend AutoCorrector

        MSG = "Versioned formulae should not use `conflicts_with`. " \
              "Use `keg_only :versioned_formula` instead."

        def on_formula_conflicts_with(node)
          if versioned_formula? && !tap_style_exception?(:versioned_formulae_conflicts_allowlist)
            offending_node(node)
            problem MSG do |corrector|
              corrector.replace(@offensive_node.source_range, "keg_only :versioned_formula")
            end
          end

          return unless parameters(node).last.respond_to? :values

          reason = parameters(node).last.values.first
          offending_node(reason)
          name = Regexp.new(@formula_name, Regexp::IGNORECASE)
          reason_text = string_content(reason).sub(name, "")
          first_word = reason_text.split.first

          if reason_text.match?(/\A[A-Z]/)
            problem "'#{first_word}' from the `conflicts_with` reason "\
                    "should be '#{first_word.downcase}'." do |corrector|
              reason_text[0] = reason_text[0].downcase
              corrector.replace(reason.source_range, "\"#{reason_text}\"")
            end
          end
          return unless reason_text.end_with?(".")

          problem "`conflicts_with` reason should not end with a period." do |corrector|
            corrector.replace(reason.source_range, "\"#{reason_text.chop}\"")
          end
        end
      end
    end
  end
end
