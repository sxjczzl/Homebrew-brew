$LOAD_PATH.unshift("#{HOMEBREW_LIBRARY_PATH}/cask/lib")
require "hbc"

module Homebrew
  module_function

  def cask
    odie "The cask command requires macOS." unless OS.mac?
    Hbc::CLI.run(*ARGV)
  end
end
