# typed: false
# frozen_string_literal: true

require "requirement"

class MacfuseRequirement < Requirement
  extend T::Sig

  def initialize(tags = [])
    odeprecated "depends_on :macfuse"
    super(tags)
  end

  download "https://macfuse.github.io/"

  satisfy(build_env: false) { self.class.binary_macfuse_installed? }

  sig { returns(T::Boolean) }
  def self.binary_macfuse_installed?
    File.exist?("/usr/local/include/macfuse/fuse.h") &&
      !File.symlink?("/usr/local/include/macfuse")
  end

  env do
    ENV.append_path "PKG_CONFIG_PATH", HOMEBREW_LIBRARY/"Homebrew/os/mac/pkgconfig/fuse"

    unless HOMEBREW_PREFIX.to_s == "/usr/local"
      ENV.append_path "HOMEBREW_LIBRARY_PATHS", "/usr/local/lib"
      ENV.append_path "HOMEBREW_INCLUDE_PATHS", "/usr/local/include/macfuse"
    end
  end

  def message
    "FUSE for macOS is required for this software. #{super}"
  end
end
