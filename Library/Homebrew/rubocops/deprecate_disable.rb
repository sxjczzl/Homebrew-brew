# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `deprecate!` and `disable!` dates.
      class DeprecateDisableDate < FormulaCop
        extend AutoCorrector

        def on_formula_deprecate!(node)
          check_date(node)
        end

        def on_formula_disable!(node)
          check_date(node)
        end

        private

        def check_date(node)
          date(node) do |date_node|
            Date.iso8601(string_content(date_node))
          rescue ArgumentError
            fixed_date_string = Date.parse(string_content(date_node)).iso8601
            offending_node(date_node)
            problem "Use `#{fixed_date_string}` to comply with ISO 8601" do |corrector|
              corrector.replace(date_node.source_range, "\"#{fixed_date_string}\"")
            end
          end
        end

        def_node_search :date, <<~EOS
          (pair (sym :date) $str)
        EOS
      end

      # This cop audits `deprecate!` and `disable!` reasons.
      class DeprecateDisableReason < FormulaCop
        extend AutoCorrector

        PUNCTUATION_MARKS = %w[. ! ?].freeze

        def on_formula_deprecate!(node)
          return if check_reason(node)

          offending_node(node)
          problem 'Add a reason for deprecation: `deprecate! because: "..."`'
        end

        def on_formula_disable!(node)
          return if check_reason(node)

          offending_node(node)
          problem 'Add a reason for disabling: `disable! because: "..."`'
        end

        private

        def check_reason(node)
          reason_found = T.let(false, T::Boolean)
          reason(node) do |reason_node|
            reason_found = true
            next if reason_node.sym_type?

            offending_node(reason_node)
            reason_string = string_content(reason_node)

            if reason_string.start_with?("it ")
              problem "Do not start the reason with `it`" do |corrector|
                corrector.replace(@offensive_node.source_range, "\"#{reason_string[3..]}\"")
              end
            end

            if PUNCTUATION_MARKS.include?(reason_string[-1])
              problem "Do not end the reason with a punctuation mark" do |corrector|
                corrector.replace(@offensive_node.source_range, "\"#{reason_string.chop}\"")
              end
            end
          end

          reason_found
        end

        def_node_search :reason, <<~EOS
          (pair (sym :because) ${str sym})
        EOS
      end
    end
  end
end
