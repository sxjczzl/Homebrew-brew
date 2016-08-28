module Homebrew
  module CoverageHelper
    def self.save_coverage
      return unless ENV["HOMEBREW_TESTS_COVERAGE"]
      return unless ENV["HOMEBREW_INTEGRATION_TEST"]

      SimpleCov.result
    end

    def self.setup_coveralls
      # Don't use Coveralls outside of CI. It will override SimpleCov's default
      # formatter causing no `index.html` to be written once all tests finish.
      return unless ENV["CI"]
      return unless ENV["HOMEBREW_TESTS_COVERAGE"]
      return if ENV["HOMEBREW_INTEGRATION_TEST"]
      return unless RUBY_VERSION.split(".").first.to_i >= 2

      require "coveralls"
      Coveralls.wear!
    end
  end
end

if ENV["HOMEBREW_TESTS_COVERAGE"]
  # This is needed only because we currently use a patched version of SimpleCov,
  # and Gems installed through Git are not available without requiring
  # `bundler/setup` first. (See also the comment in `test/Gemfile`.)
  # Remove the next line when we switch back to a stable SimpleCov release.
  require "bundler/setup"

  # For SimpleCov to find `.simplecov`, we need to make sure it's in the current
  # working directory, no matter where this bootstrap code is loaded from.
  Dir.chdir(File.expand_path("../..", __FILE__)) do
    require "simplecov"
  end
end
