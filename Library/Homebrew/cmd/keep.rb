# frozen_string_literal: true

require "formula_keeper"
require "cli/parser"

module Homebrew
  module_function

  def keep_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `keep` [<formula>]

        Keep the specified <formula>, preventing them from being uninstalled
        when issuing the `brew uninstall` <formula> command without `--force`.

        If no arguments are provided, list all formula being kept.

        See also `unkeep`.
      EOS
    end
  end

  def keep
    args = keep_args.parse

    if args.no_named?
      puts FormulaKeeper.kept_formula_names
      return
    end

    args.resolved_formulae.each do |f|
      if FormulaKeeper.keeping?(f)
        opoo "Already keeping #{f.name}"
      elsif !FormulaKeeper.keepable?(f)
        onoe "#{f.name} not installed"
      else
        FormulaKeeper.keep(f)
      end
    end
  end
end
