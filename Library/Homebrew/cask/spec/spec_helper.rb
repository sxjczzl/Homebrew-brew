$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require "pathname"
require "rspec/its"
require "rspec/wait"

require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
require "global"

# add Homebrew-Cask to load path
$LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.join("cask", "lib").to_s)

require "test/support/helper/shutup"

require "test/support/helper/cask/audit_matchers"
require "test/support/helper/cask/expectations_hash_helper"
require "test/support/helper/cask/file_helper"
require "test/support/helper/cask/install_helper"
require "test/support/helper/cask/kernel_at_exit_hacks"
require "test/support/helper/cask/sha256_helper"

require "hbc"

# create and override default directories
Hbc.appdir = Pathname.new(TEST_TMPDIR).join("Applications").tap(&:mkpath)
Hbc.cache.mkpath
Hbc.caskroom = Hbc.default_caskroom.tap(&:mkpath)
Hbc.default_tap = Tap.fetch("caskroom", "spec").tap do |tap|
  # link test casks
  FileUtils.mkdir_p tap.path.dirname
  FileUtils.ln_s TEST_FIXTURE_DIR.join("cask"), tap.path
end

RSpec.configure do |config|
  config.order = :random
  config.include(Test::Helper::Shutup)
end
