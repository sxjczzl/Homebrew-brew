# typed: true
# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop ensures that no other livecheck information is provided for
      # skipped formulae.
      #
      # @api private
      class LivecheckSkip < FormulaCop
        extend AutoCorrector

        def on_formula_livecheck(livecheck_node)
          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.blank?

          return if find_every_method_call_by_name(livecheck_node).length < 3

          offending_node(livecheck_node)
          problem "Skipped formulae must not contain other livecheck information." do |corrector|
            skip = find_every_method_call_by_name(livecheck_node, :skip).first
            skip = find_strings(skip).first
            skip = string_content(skip) if skip.present?
            corrector.replace(
              livecheck_node.source_range,
              <<~EOS.strip,
                livecheck do
                    skip#{" \"#{skip}\"" if skip.present?}
                  end
              EOS
            )
          end
        end
      end

      # This cop ensures that a `url` is specified in the `livecheck` block.
      #
      # @api private
      class LivecheckUrlProvided < FormulaCop
        def on_formula_livecheck(livecheck_node)
          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.present?

          formula_node = find_every_method_call_by_name(livecheck_node, :formula).first
          cask_node = find_every_method_call_by_name(livecheck_node, :cask).first
          return if formula_node.present? || cask_node.present?

          livecheck_url = find_every_method_call_by_name(livecheck_node, :url).first
          return if livecheck_url.present?

          offending_node(livecheck_node)
          problem "A `url` must be provided to livecheck."
        end
      end

      # This cop ensures that a supported symbol (`head`, `stable, `homepage`)
      # is used when the livecheck `url` is identical to one of these formula URLs.
      #
      # @api private
      class LivecheckUrlSymbol < FormulaCop
        extend AutoCorrector

        def on_formula_class(_class_node)
          @livecheck_url_node = nil
          @formula_urls = {}
        end

        def on_formula_livecheck(livecheck_node)
          return if @livecheck_url_node

          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.present?

          @livecheck_url_node = find_every_method_call_by_name(livecheck_node, :url).first
        end

        def on_formula_head(node)
          head_url = if node.block_type?
            url_node = find_every_method_call_by_name(node, :url).first
            return if url_node.nil?

            find_strings(url_node).first
          else
            find_strings(node).first
          end
          return if head_url.nil?

          @formula_urls[:head] = string_content(head_url)
        end

        def on_formula_url(node)
          stable_url = find_strings(node).first
          return if stable_url.nil?

          block_url = node.each_ancestor(:block, :class).first&.block_type?
          return if block_url

          @formula_urls[:stable] = string_content(stable_url)
        end

        def on_formula_stable(node)
          url_node = find_every_method_call_by_name(node, :url).first
          return if url_node.nil?

          stable_url = find_strings(url_node).first
          return if stable_url.nil?

          @formula_urls[:stable] = string_content(stable_url)
        end

        def on_formula_homepage(node)
          homepage_url = find_strings(node).first
          return if homepage_url.nil?

          @formula_urls[:homepage] = string_content(homepage_url)
        end

        def on_formula_class_end(_class_node)
          return if @livecheck_url_node.nil?

          livecheck_url = find_strings(@livecheck_url_node).first
          return if livecheck_url.blank?

          livecheck_url = string_content(livecheck_url)

          @formula_urls.each do |symbol, url|
            next if url != livecheck_url && url != "#{livecheck_url}/" && "#{url}/" != livecheck_url

            offending_node(@livecheck_url_node)
            problem "Use `url :#{symbol}`" do |corrector|
              corrector.replace(@livecheck_url_node.source_range, "url :#{symbol}")
            end
            break
          end
        end
      end

      # This cop ensures that the `regex` call in the `livecheck` block uses parentheses.
      #
      # @api private
      class LivecheckRegexParentheses < FormulaCop
        extend AutoCorrector

        def on_formula_livecheck(livecheck_node)
          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.present?

          livecheck_regex_node = find_every_method_call_by_name(livecheck_node, :regex).first
          return if livecheck_regex_node.blank?

          return if parentheses?(livecheck_regex_node)

          offending_node(livecheck_regex_node)
          problem "The `regex` call should always use parentheses." do |corrector|
            pattern = livecheck_regex_node.source.split[1..].join
            corrector.replace(livecheck_regex_node.source_range, "regex(#{pattern})")
          end
        end
      end

      # This cop ensures that the pattern provided to livecheck's `regex` uses `\.t` instead of
      # `\.tgz`, `\.tar.gz` and variants.
      #
      # @api private
      class LivecheckRegexExtension < FormulaCop
        extend AutoCorrector

        TAR_PATTERN = /\\?\.t(ar|(g|l|x)z$|[bz2]{2,4}$)(\\?\.((g|l|x)z)|[bz2]{2,4}|Z)?$/i.freeze

        def on_formula_livecheck(livecheck_node)
          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.present?

          livecheck_regex_node = find_every_method_call_by_name(livecheck_node, :regex).first
          return if livecheck_regex_node.blank?

          regex_node = livecheck_regex_node.descendants.first
          pattern = string_content(find_strings(regex_node).first)
          match = pattern.match(TAR_PATTERN)
          return if match.blank?

          offending_node(regex_node)
          problem "Use `\\.t` instead of `#{match}`" do |corrector|
            node = find_strings(regex_node).first
            correct = node.source.gsub(TAR_PATTERN, "\\.t")
            corrector.replace(node.source_range, correct)
          end
        end
      end

      # This cop ensures that a `regex` is provided when `strategy :page_match` is specified
      # in the `livecheck` block.
      #
      # @api private
      class LivecheckRegexIfPageMatch < FormulaCop
        def on_formula_livecheck(livecheck_node)
          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.present?

          livecheck_strategy_node = find_every_method_call_by_name(livecheck_node, :strategy).first
          return if livecheck_strategy_node.blank?

          strategy = livecheck_strategy_node.descendants.first.source
          return if strategy != ":page_match"

          livecheck_regex_node = find_every_method_call_by_name(livecheck_node, :regex).first
          return if livecheck_regex_node.present?

          offending_node(livecheck_node)
          problem "A `regex` is required if `strategy :page_match` is present."
        end
      end

      # This cop ensures that the `regex` provided to livecheck is case-insensitive,
      # unless sensitivity is explicitly required for proper matching.
      #
      # @api private
      class LivecheckRegexCaseInsensitive < FormulaCop
        extend AutoCorrector

        MSG = "Regexes should be case-insensitive unless sensitivity is explicitly required for proper matching."

        def on_formula_livecheck(livecheck_node)
          skip = find_every_method_call_by_name(livecheck_node, :skip).first
          return if skip.present?

          livecheck_regex_node = find_every_method_call_by_name(livecheck_node, :regex).first
          return if livecheck_regex_node.blank?

          regex_node = livecheck_regex_node.descendants.first
          options_node = regex_node.regopt
          return if options_node.source.include?("i")

          return if tap_style_exception? :regex_case_sensitive_allowlist

          offending_node(regex_node)
          problem MSG do |corrector|
            node = regex_node.regopt
            corrector.replace(node.source_range, "i#{node.source}".chars.sort.join)
          end
        end
      end
    end
  end
end
