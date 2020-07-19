# frozen_string_literal: true

require "cli/parser"
require "utils/github"

module Homebrew
  module_function

  def sponsors_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `sponsors`

        Print a Markdown summary of Homebrew's GitHub Sponsors, suitable for pasting into a README.
      EOS
    end
  end

  def sponsors
    sponsors_args.parse

    all_sponsors = 0
    org_sponsors = 0
    named_sponsors = []

    GitHub.sponsors_by_tier("Homebrew").each do |tier|
      all_sponsors += tier["count"]
      org_sponsors += tier["sponsors"].count { |s| s["type"] == "organization" }
      named_sponsors += tier["sponsors"] if tier["tier"] >= 100
    end

    user_sponsors = all_sponsors - named_sponsors.length - org_sponsors

    items = named_sponsors.map { |s| "[#{s["name"]}](https://github.com/#{s["login"]})" }
    items << "#{user_sponsors} #{"user".pluralize(user_sponsors)}" unless user_sponsors.zero?
    items << "#{org_sponsors} #{"organisation".pluralize(org_sponsors)}" unless org_sponsors.zero?

    puts "Homebrew is generously supported by #{items.to_sentence} via [GitHub Sponsors](https://github.com/sponsors/Homebrew)."
  end
end
