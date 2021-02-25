# typed: false
# frozen_string_literal: true

require "utils/topological_hash"

module Utils
  # Helper module for installing formulae/casks.
  #
  # @api private
  module Install
    module_function

    def graph_dependencies(cask_or_formula, acc = nil)
      acc = TopologicalHash.new if acc.nil?
      return acc if acc.key?(cask_or_formula)

      if cask_or_formula.is_a?(Cask::Cask)
        formula_deps = cask_or_formula.depends_on.formula.map { |f| Formula[f] }
        cask_deps = cask_or_formula.depends_on.cask.map { |c| Cask::CaskLoader.load(c, config: nil) }
      else
        formula_deps = cask_or_formula.deps.reject(&:build?).map(&:to_formula)
        cask_deps = cask_or_formula.requirements.map(&:cask).compact
                                   .map { |c| Cask::CaskLoader.load(c, config: nil) }
      end

      acc[cask_or_formula] ||= []
      acc[cask_or_formula] += formula_deps
      acc[cask_or_formula] += cask_deps

      formula_deps.each do |f|
        graph_dependencies(f, acc)
      end

      cask_deps.each do |c|
        graph_dependencies(c, acc)
      end

      acc
    end
  end
end
