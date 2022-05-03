# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `option`s in formulae.
      class Options < FormulaCop
        DEPRECATION_MSG = "macOS has been 64-bit only since 10.6 so 32-bit options are deprecated."
        UNI_DEPRECATION_MSG = "macOS has been 64-bit only since 10.6 so universal options are deprecated."

        DEP_OPTION = "Formulae in homebrew/core should not use `deprecated_option`."
        OPTION = "Formulae in homebrew/core should not use `option`."

        def on_formula_class(_class_node)
          @deprecated_check_options = []
        end

        def on_formula_option(node)
          offending_node(node)
          problem OPTION if core_tap?

          option = parameters(node).first
          problem DEPRECATION_MSG if regex_match_group(option, /32-bit/)

          option = string_content(option)
          problem UNI_DEPRECATION_MSG if option == "universal"

          if option !~ /with(out)?-/ &&
             option != "cxx11" &&
             option != "universal"
            problem "Options should begin with with/without."\
                    " Migrate '--#{option}' with `deprecated_option`."
          end

          return unless option =~ /^with(out)?-(?:checks?|tests)$/

          @deprecated_check_options << [node, Regexp.last_match(1)]
        end

        def on_formula_deprecated_option(node)
          return unless core_tap?

          offending_node(node)
          problem DEP_OPTION
        end

        def on_formula_depends_on(node)
          if !depends_on_matches?(node, "check", :optional) && !depends_on_matches?(node, "check", :recommended)
            return
          end

          @depends_on_check = true
        end

        def on_formula_class_end(_class_node)
          return if @depends_on_check

          @deprecated_check_options.each do |node, with_suffix|
            option = string_content(parameters(node).first)
            offending_node(node)
            problem "Use '--with#{with_suffix}-test' instead of '--#{option}'."\
                    " Migrate '--#{option}' with `deprecated_option`."
          end
        end
      end
    end
  end
end
