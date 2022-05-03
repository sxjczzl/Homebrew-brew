# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for various problems in a formula's source code.
      #
      # @api private
      class Text < FormulaCop
        extend AutoCorrector

        def on_formula_source(processed_source)
          @go_require = nil
          @go_resource_found = false

          requires = find_method_calls_by_name(processed_source.ast, :require)
          requires.each do |req|
            if parameters_passed?(req, "formula")
              range = req.source_range
              add_offense(range, message: "`require \"formula\"` is now unnecessary") do |corrector|
                corrector.remove(range_with_surrounding_space(range: range))
              end
            elsif parameters_passed?(req, "language/go")
              @go_require = req
            end
          end
        end

        def on_formula_class(_class_node)
          @plist_options_found = false
          @plist_node = nil
          @ssl_type = nil
        end

        def on_formula_plist_options(_node)
          @plist_options_found = true
        end

        def on_formula_plist(node)
          @plist_node = node
        end

        def on_formula_depends_on(node)
          new_ssl_type = if depends_on_matches?(node, "openssl") || depends_on_matches?(node, "openssl@1.1") ||
                            depends_on_matches?(node, "openssl@3")
            "openssl"
          elsif depends_on_matches?(node, "libressl")
            "libressl"
          end

          if @ssl_type && new_ssl_type && @ssl_type != new_ssl_type
            problem "Formulae should not depend on both OpenSSL and LibreSSL (even optionally)."
          end

          @ssl_type = new_ssl_type if new_ssl_type

          return unless core_tap?
          return if !depends_on_matches?(node, "veclibfort") && !depends_on_matches?(node, "lapack")

          problem "Formulae in homebrew/core should use OpenBLAS as the default serial linear algebra library."
        end

        def on_formula_go_resource(_node)
          @go_resource_found = true
        end

        def on_formula_send(send_node)
          if send_node.method_name == :factory && instance_method_call?(send_node, "Formula")
            problem "\"Formula.factory(name)\" is deprecated in favor of \"Formula[name]\""
          elsif send_node.method_name == :system
            if parameters_passed?(send_node, "xcodebuild")
              problem %q(use "xcodebuild *args" instead of "system 'xcodebuild', *args")
            elsif parameters_passed?(send_node, "dep", "ensure") && !parameters_passed?(send_node, /vendor-only/) &&
                  @formula_name != "goose" # needed in 2.3.0
              offending_node(send_node)
              problem "use \"dep\", \"ensure\", \"-vendor-only\""
            elsif parameters_passed?(send_node, "cargo", "build") && !parameters_passed?(send_node, /--lib/)
              offending_node(send_node)
              problem "use \"cargo\", \"install\", *std_cargo_args"
            elsif parameters_passed?(send_node, /make && make/)
              offending_node(send_node)
              problem "Use separate `make` calls"
            end
          elsif (path = prefix_path(send_node)) &&
                (match = path.match(%r{^(bin|include|libexec|lib|sbin|share|Frameworks)(?:/| |$)}))
            offending_node(send_node)
            problem "Use `#{match[1].downcase}` instead of `prefix + \"#{match[1]}\"`"
          end
        end

        def on_formula_install(node)
          find_method_with_args(node, :system, "go", "get") do
            problem "Do not use `go get`. Please ask upstream to implement Go vendoring"
          end
        end

        def on_formula_dstr(node)
          node.each_descendant(:begin) do |interpolation_node|
            next unless interpolation_node.source.match?(/#\{\w+\s*\+\s*['"][^}]+\}/)

            offending_node(interpolation_node)
            problem "Do not concatenate paths in string interpolation"
          end
        end

        def on_formula_class_end(_class_node)
          return if @plist_options_found
          return unless @plist_node

          offending_node(@plist_node)
          problem "Please set plist_options when using a formula-defined plist."
        end

        def on_formula_source_end(_processed_source)
          return if @go_resource_found
          return unless @go_require

          offending_node(@go_require)
          problem "require \"language/go\" is unnecessary unless using `go_resource`s"
        end

        # Find: prefix + "foo"
        def_node_matcher :prefix_path, <<~EOS
          (send (send nil? :prefix) :+ (str $_))
        EOS
      end
    end

    module FormulaAuditStrict
      # This cop contains stricter checks for various problems in a formula's source code.
      #
      # @api private
      class Text < FormulaCop
        def on_formula_go_resource(_node)
          problem "`go_resource`s are deprecated. Please ask upstream to implement Go vendoring"
        end

        def on_formula_send(send_node)
          if send_node.method_name == :env
            if parameters_passed?(send_node, :userpaths)
              problem "`env :userpaths` in homebrew/core formulae is deprecated"
            elsif core_tap? && parameters_passed?(send_node, :std)
              problem "`env :std` in homebrew/core formulae is deprecated"
            end
          elsif share_path_starts_with?(send_node, @formula_name)
            offending_node(send_node)
            problem "Use `pkgshare` instead of `share/\"#{@formula_name}\"`"
          end
        end

        def on_formula_dstr(node)
          return unless interpolated_share_path_starts_with?(node, "/#{@formula_name}")

          offending_node(node)
          problem "Use `\#{pkgshare}` instead of `\#{share}/#{@formula_name}`"
        end

        # Check whether value starts with the formula name and then a "/", " " or EOS.
        def path_starts_with?(path, starts_with)
          path.match?(%r{^#{Regexp.escape(starts_with)}(/| |$)})
        end

        # Find "#{share}/foo"
        def_node_matcher :interpolated_share_path_starts_with?, <<~EOS
          (dstr (begin (send nil? :share)) (str #path_starts_with?(%1)))
        EOS

        # Find share/"foo"
        def_node_matcher :share_path_starts_with?, <<~EOS
          (send (send nil? :share) :/ (str #path_starts_with?(%1)))
        EOS
      end
    end
  end
end
