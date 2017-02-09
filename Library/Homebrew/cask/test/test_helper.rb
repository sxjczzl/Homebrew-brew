$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew"))
$LOAD_PATH.unshift(File.expand_path("#{ENV["HOMEBREW_LIBRARY"]}/Homebrew/test/support/lib"))

require "simplecov" if ENV["HOMEBREW_TESTS_COVERAGE"]
require "global"

begin
  require "minitest/autorun"
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
  require "parallel_tests/test/runtime_logger"
  require "mocha/setup"
rescue LoadError
  abort "Run `bundle install` or install the mocha and minitest gems before running the tests"
end

# add Homebrew-Cask to load path
$LOAD_PATH.push(HOMEBREW_LIBRARY_PATH.join("cask", "lib").to_s)

require "test/support/helper/minitest/spec"

def sudo(*args)
  %w[/usr/bin/sudo -E --] + args.flatten
end

# our baby
require "hbc"

# create and override default directories
Hbc.appdir = Pathname.new(TEST_TMPDIR).join("Applications").tap(&:mkpath)
Hbc.cache.mkpath
Hbc.caskroom = Hbc.default_caskroom.tap(&:mkpath)
Hbc.default_tap = Tap.fetch("caskroom", "test").tap do |tap|
  # link test casks
  FileUtils.mkdir_p tap.path.dirname
  FileUtils.ln_s TEST_FIXTURE_DIR.join("cask"), tap.path
end

# pretend that the caskroom/cask Tap is installed
FileUtils.ln_s Pathname.new(ENV["HOMEBREW_LIBRARY"]).join("Taps", "caskroom", "homebrew-cask"), Tap.fetch("caskroom", "cask").path

# Extend MiniTest API with support for RSpec-style shared examples
require "test/support/helper/cask/shared_examples"
require "test/support/helper/cask/shared_examples/dsl_base"
require "test/support/helper/cask/shared_examples/staged"

require "test/support/helper/cask/fake_dirs"
require "test/support/helper/cask/fake_system_command"
require "test/support/helper/cask/file_helper"
require "test/support/helper/cask/install_helper"
require "test/support/helper/cask/cleanup"
require "test/support/helper/cask/never_sudo_system_command"
