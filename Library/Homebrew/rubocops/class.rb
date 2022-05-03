# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop makes sure that {Formula} is used as superclass.
      #
      # @api private
      class ClassName < FormulaCop
        extend AutoCorrector

        DEPRECATED_CLASSES = %w[
          GithubGistFormula
          ScriptFileFormula
          AmazonWebServicesFormula
        ].freeze

        def on_formula_class(class_node)
          parent_class = class_name(class_node.parent_class)
          return unless DEPRECATED_CLASSES.include?(parent_class)

          problem "#{parent_class} is deprecated, use Formula instead" do |corrector|
            corrector.replace(class_node.parent_class.source_range, "Formula")
          end
        end
      end

      # This cop makes sure that a `test` block contains a proper test.
      #
      # @api private
      class Test < FormulaCop
        extend AutoCorrector

        def on_formula_test(node)
          offending_node(node)

          if node.body.nil?
            problem "`test do` should not be empty"
            return
          end

          problem "`test do` should contain a real test" if node.body.single_line? && node.body.source.to_s == "true"

          test_calls(node) do |call_node, params|
            p1, p2 = params
            if (match = string_content(p1).match(%r{(/usr/local/(s?bin))}))
              offending_node(p1)
              problem "use \#{#{match[2]}} instead of #{match[1]} in #{call_node}" do |corrector|
                corrector.replace(p1.source_range, p1.source.sub(match[1], "\#{#{match[2]}}"))
              end
            end

            if call_node == :shell_output && p2&.numeric_type? && p2.value.zero?
              offending_node(p2)
              problem "Passing 0 to shell_output() is redundant" do |corrector|
                corrector.remove(range_with_surrounding_comma(range_with_surrounding_space(range: p2.source_range,
                                                                                           side:  :left)))
              end
            end
          end
        end

        def_node_search :test_calls, <<~EOS
          (send nil? ${:system :shell_output :pipe_output} $...)
        EOS
      end
    end

    module FormulaAuditStrict
      # This cop makes sure that a `test` block exists.
      #
      # @api private
      class TestPresent < FormulaCop
        def on_formula_class(_class_node)
          @test_present = false
        end

        def on_formula_test(_node)
          @test_present = true
        end

        def on_formula_class_end(class_node)
          return if @test_present

          offending_node(class_node)
          problem "A `test do` test block should be added"
        end
      end
    end
  end
end
