require "pathname"

HOMEBREW_LIBRARY_PATH = Pathname(__dir__).realpath

module LoadPath
  def self.<<(pathname)
    return if $LOAD_PATH.include?(pathname.to_s)
    $LOAD_PATH << pathname.to_s
  end
end

LoadPath << HOMEBREW_LIBRARY_PATH

require "vendor/bundle-standalone/bundler/setup"
