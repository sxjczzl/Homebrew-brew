# typed: false
# frozen_string_literal: true

require "searchable"
require "description_cache_store"
require "algolia"

module Homebrew
  # Helper module for searching formulae or casks.
  #
  # @api private
  module Search
    def query_regexp(query)
      if (m = query.match(%r{^/(.*)/$}))
        Regexp.new(m[1])
      else
        query
      end
    rescue RegexpError
      raise "#{query} is not a valid regex."
    end

    def search_descriptions(string_or_regex, args)
      return if args.cask?

      ohai "Formulae"
      CacheStoreDatabase.use(:descriptions) do |db|
        cache_store = DescriptionCacheStore.new(db)
        Descriptions.search(string_or_regex, :desc, cache_store).print
      end
    end

    def search_taps(query, silent: false)
      if query.match?(Regexp.union(HOMEBREW_TAP_FORMULA_REGEX, HOMEBREW_TAP_CASK_REGEX))
        _, _, query = query.split("/", 3)
      end

      results = { formulae: [], casks: [] }

      return results if Homebrew::EnvConfig.no_github_api?

      unless silent
        # Use stderr to avoid breaking parsed output
        $stderr.puts Formatter.headline("Searching taps on Algolia...", color: :blue)
      end

      # TODO: consider adding a HOMEBREW_INSTALL_FROM_API check here too
      # if `Cask::Cask.all` works under that setup in the future.
      algolia_results = if Tap.default_cask_tap.installed?
        # Algolia (currently) only indexes Homebrew/core and Homebrew/cask.
        # So don't bother searching if we already have those installed.
        []
      else
        begin
          Algolia.search(query,
                         filters:                "site:formulae AND tags:formula AND NOT tags:analytics",
                         searchable_attributes:  ["hierarchy.lvl1"], # Only search names
                         attributes_to_retrieve: ["hierarchy.lvl0", "hierarchy.lvl1"])
        rescue Algolia::APIError
          opoo "Error searching on Algolia."
          []
        end
      end

      algolia_results.each do |result|
        hierarchy = result.fetch("hierarchy")
        name = hierarchy.fetch("lvl1")
        case (type = hierarchy.fetch("lvl0"))
        when "Formulae"
          # We only index Homebrew/core and that (should?) always be available for local searching.
        when "Casks"
          results[:casks] << "homebrew/cask/#{name}"
        else
          opoo "Unknown result type \"#{type}\"!"
        end
      end

      unless silent
        # Use stderr to avoid breaking parsed output
        $stderr.puts Formatter.headline("Searching taps on GitHub...", color: :blue)
      end

      matches = begin
        GitHub.search_code(
          user:      "Homebrew",
          path:      ["Formula", "Casks", "."],
          filename:  query,
          extension: "rb",
        )
      rescue GitHub::API::Error => e
        opoo "Error searching on GitHub: #{e}\n"
        nil
      end

      matches.each do |match|
        name = File.basename(match["path"], ".rb")
        tap = Tap.fetch(match["repository"]["full_name"])
        full_name = "#{tap.name}/#{name}"

        next if tap.installed?
        next if tap.core_tap? || tap == Tap.default_cask_tap # Handled by Algolia

        if match["path"].start_with?("Casks/")
          results[:casks] << full_name
        else
          results[:formulae] << full_name
        end
      end

      results[:formulae].sort!
      results[:casks].sort!

      results
    end

    def search_formulae(string_or_regex)
      if string_or_regex.is_a?(String) && string_or_regex.match?(HOMEBREW_TAP_FORMULA_REGEX)
        return begin
          [Formulary.factory(string_or_regex).name]
        rescue FormulaUnavailableError
          []
        end
      end

      aliases = Formula.alias_full_names
      results = (Formula.full_names + aliases)
                .extend(Searchable)
                .search(string_or_regex)
                .sort

      results |= Formula.fuzzy_search(string_or_regex).map { |n| Formulary.factory(n).full_name }

      results.map do |name|
        formula, canonical_full_name = begin
          f = Formulary.factory(name)
          [f, f.full_name]
        rescue
          [nil, name]
        end

        # Ignore aliases from results when the full name was also found
        next if aliases.include?(name) && results.include?(canonical_full_name)

        if formula&.any_version_installed?
          pretty_installed(name)
        else
          name
        end
      end.compact
    end

    def search_casks(_string_or_regex)
      []
    end
  end
end

require "extend/os/search"
