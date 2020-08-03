# frozen_string_literal: true

module DependenciesHelpers
  module Compat
    @printed_includes_ignores_warning = false

    def argv_includes_ignores(argv)
      unless @printed_includes_ignores_warning
        odeprecated "Homebrew.argv_includes_ignores", "Homebrew.args_includes_ignores"
        @printed_includes_ignores_warning = true
      end
      args_includes_ignores(Homebrew::CLI::Parser.new.parse(argv, ignore_invalid_options: true))
    end
  end

  prepend Compat
end
