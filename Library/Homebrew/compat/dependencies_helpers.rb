# frozen_string_literal: true

module DependenciesHelpers
  module Compat
    def argv_includes_ignores(argv)
      odeprecated "Homebrew.argv_includes_ignores", "Homebrew.args_includes_ignores"
      args_includes_ignores(Homebrew::CLI::Parser.new.parse(argv, ignore_invalid_options: true))
    end
  end

  prepend Compat
end
