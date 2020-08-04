# frozen_string_literal: true

require "formula_keeper"
require "cli/parser"

module Homebrew
  module_function

  def keep_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `keep` <formula>

        Keep the specified <formula>, preventing them from being uninstalled
        when issuing the `brew uninstall` <formula> command without `--force`.
        See also `unkeep`.
      EOS

      min_named :formula
    end
  end

  def keep
    args = keep_args.parse

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
