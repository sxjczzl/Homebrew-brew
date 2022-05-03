# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop makes sure that caveats don't recommend unsupported or unsafe operations.
      #
      # @example
      #   # bad
      #   def caveats
      #     <<~EOS
      #       Use `setuid` to allow running the exeutable by non-root users.
      #     EOS
      #   end
      #
      #   # good
      #   def caveats
      #     <<~EOS
      #       Use `sudo` to run the executable.
      #     EOS
      #   end
      #
      # @api private
      class Caveats < FormulaCop
        def on_formula_caveats(node)
          find_strings(node).each do |n|
            next unless regex_match_group(n, /\bsetuid\b/i)

            problem "Don't recommend setuid in the caveats, suggest sudo instead."
          end
        end
      end
    end
  end
end
