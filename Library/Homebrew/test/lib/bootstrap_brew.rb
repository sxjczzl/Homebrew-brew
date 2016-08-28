require "bootstrap_coverage"
require "integration_mocks"

# We load `brew.rb` indirectly, as otherwise we won't get coverage data.
require File.expand_path("../../../brew.rb", __FILE__)
