# frozen_string_literal: true

require "formula"
require "tab"
require "cli/parser"

require_relative "deps"

module Homebrew
  module_function

  def leaves_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `leaves`

        List installed formulae that are not dependencies of another installed formula.
      EOS
      switch "--1",
             description: "Only show dependencies one level down, instead of recursing."
      switch "--tree",
             description: "Show dependencies as a tree."
      switch :debug
      max_named 0
    end
  end

  def leaves
    leaves_args.parse

    installed = Formula.installed.sort
    deps_of_installed = installed.flat_map(&:runtime_formula_dependencies)
    leaves = installed - deps_of_installed

    if args.tree?
      puts_deps_tree leaves, !args.send("1?")
    else
      leaves.each(&method(:puts))
    end
  end
end
