# typed: true
# frozen_string_literal: true

require "ast_constants"

module RuboCop
  module Cop
    # It's the formula police force! 🚔
    # The dispatcher for all formula cops.
    #
    # @api private
    class FormulaForce < Force
      def investigate(processed_source)
        file_path = processed_source.buffer.name
        return unless file_path_allowed?(file_path)

        root_node = processed_source.ast
        return unless root_node

        formula_found = T.let(false, T::Boolean)
        if root_node.class_type? && formula_class?(root_node)
          formula_found = true
          run_file_hooks(file_path, processed_source)
          process_formula(root_node)
        elsif root_node.begin_type?
          root_node.each_child_node(:class) do |class_node|
            next false unless formula_class?(class_node)

            unless formula_found
              run_file_hooks(file_path, processed_source)
              formula_found = true
            end

            process_formula(class_node)
          end
        end

        return unless formula_found

        run_hook :on_formula_source_end, processed_source
      end

      private

      def file_path_allowed?(file_path)
        return true if file_path.nil? # file_path is nil when source is directly passed to the cop, e.g. in specs

        file_path !~ Regexp.union([%r{/Library/Homebrew/compat/}, %r{/Library/Homebrew/test/}])
      end

      def formula_class?(class_node)
        class_names = %w[
          Formula
          GithubGistFormula
          ScriptFileFormula
          AmazonWebServicesFormula
        ]

        parent = class_node.parent_class
        parent && class_names.include?(parent.const_name)
      end

      def run_file_hooks(file_path, processed_source)
        run_hook :on_formula_file, file_path
        run_hook :on_formula_source, processed_source
      end

      def process_formula(class_node)
        run_hook :on_formula_class, class_node

        components = FORMULA_COMPONENT_PRECEDENCE_LIST.flatten
        method_call_components = components.select { |component| component[:type] == :method_call }
                                           .map { |component| component[:name] }
        block_call_components = components.select { |component| component[:type] == :block_call }
                                          .map { |component| component[:name] }
        method_def_components = components.select { |component| component[:type] == :method_definition }
                                          .map { |component| component[:name] }

        report_descendant = lambda do |node|
          components_to_check = case node.type
          when :send
            method_call_components if valid_send_node?(node)
          when :block
            block_call_components if node.send_node.receiver.nil?
          when :def
            method_def_components
          end

          if components_to_check&.include?(node.method_name)
            run_hook :"on_formula_#{node.method_name}", node
          else
            run_hook :"on_formula_#{node.type}", node
          end
        end
        report_descendant.call(class_node.body)
        class_node.body.each_descendant(&report_descendant)

        run_hook :on_formula_class_end, class_node
      end

      def valid_send_node?(node)
        return false unless node.receiver.nil?
        return false if node.arguments.empty? && !node.method_name.to_s.end_with?("!")
        return false if node.parent&.block_type? && node.parent.send_node == node

        true
      end
    end
  end
end
