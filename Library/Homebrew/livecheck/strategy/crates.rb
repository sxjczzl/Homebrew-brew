# typed: false
# frozen_string_literal: true

module Homebrew
  module Livecheck
    module Strategy
      # The {Crates} strategy identifies versions of software at crates.io by
      # checking the listed versions for a crate at docs.rs.
      #
      # Crates URLs take one of the following formats:
      #
      # * `https://crates.io/api/v1/crates/brew/1.2.3/download`
      # * `https://static.crates.io/crates/brew/brew-1.2.3.crate`
      #
      # @api public
      class Crates
        NICE_NAME = "crates"

        # The `Regexp` used to determine if the strategy applies to the URL.
        URL_MATCH_REGEX = %r{^https?://(?:static\.)?crates\.io(?:/api/v1)?/crates/[^/]+/}i.freeze

        # Whether the strategy can be applied to the provided URL.
        #
        # @param url [String] the URL to match against
        # @return [Boolean]
        def self.match?(url)
          URL_MATCH_REGEX.match?(url)
        end

        # Generates a URL and regex (if one isn't provided) and passes them
        # to {PageMatch.find_versions} to identify versions in the content.
        #
        # @param url [String] the URL of the content to check
        # @param regex [Regexp] a regex used for matching versions in content
        # @return [Hash]
        def self.find_versions(url, regex = nil)
          %r{/crates/(?<package_name>[^/]+)/}i =~ url

          # docs.rs crate page containing version listing
          page_url = "https://docs.rs/crate/#{package_name}"

          # Example regex: `%r{href=.*?/crate/brew/v?(\d+(?:\.\d+)+)"}i`
          regex ||= %r{href=.*?/crate/#{Regexp.escape(package_name)}/v?(\d+(?:\.\d+)+)"}i

          Homebrew::Livecheck::Strategy::PageMatch.find_versions(page_url, regex)
        end
      end
    end
  end
end
