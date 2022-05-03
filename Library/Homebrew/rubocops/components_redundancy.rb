# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks if redundant components are present and for other component errors.
      #
      # - `url|checksum|mirror` should be inside `stable` block
      # - `head` and `head do` should not be simultaneously present
      # - `bottle :unneeded`/`:disable` and `bottle do` should not be simultaneously present
      # - `stable do` should not be present without a `head` spec
      #
      # @api private
      class ComponentsRedundancy < FormulaCop
        HEAD_MSG = "`head` and `head do` should not be simultaneously present"
        BOTTLE_MSG = "`bottle :modifier` and `bottle do` should not be simultaneously present"
        STABLE_MSG = "`stable do` should not be present without a `head` spec"

        def on_formula_class(_class_node)
          @stable_block = nil
          @head_type = nil
          @bottle_type = nil
        end

        def on_formula_url(node)
          parent = node.each_ancestor(:begin, :block, :class).first || node.parent

          node.arguments.each do |arg|
            next unless arg.hash_type?

            url_args = arg.keys.each.map(&:value)
            if method_called?(parent, :sha256) && url_args.include?(:tag) && url_args.include?(:revision)
              problem "Do not use both sha256 and tag/revision."
            end
          end
        end

        def on_formula_stable(node)
          @stable_block = node
        end

        def on_formula_head(node)
          if @head_type && @head_type != node.type
            offending_node(node)
            problem HEAD_MSG
          end

          @head_type = node.type
        end

        def on_formula_bottle(node)
          if @bottle_type && @bottle_type != node.type
            offending_node(node)
            problem BOTTLE_MSG
          end

          @bottle_type = node.type
        end

        def on_formula_class_end(class_node)
          return unless @stable_block

          [:url, :sha256, :mirror].each do |method_name|
            next unless method_called?(class_node.body, method_name)

            problem "`#{method_name}` should be put inside `stable` block"
          end

          return if @head_type

          offending_node(@stable_block)
          problem STABLE_MSG
        end
      end
    end
  end
end
