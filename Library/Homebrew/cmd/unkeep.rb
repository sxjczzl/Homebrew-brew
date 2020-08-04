# frozen_string_literal: true

require "formula_keeper"
require "cli/parser"

module Homebrew
  module_function

  def unkeep_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `unkeep` <formula>

        Unkeep <formula>, allowing them to be uninstalled by `brew uninstall`
        <formula> without `--force`. See also `keep`.
      EOS

      min_named :formula
    end
  end

  def unkeep
    args = unkeep_args.parse

    args.resolved_formulae.each do |f|
      if FormulaKeeper.keeping?(f)
        FormulaKeeper.unkeep(f)
      elsif !FormulaKeeper.keepable?(f)
        onoe "#{f.name} not installed"
      else
        opoo "Not keeping #{f.name}"
      end
    end
  end
end
