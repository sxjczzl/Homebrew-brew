require "requirement"

class MonoRequirement < Requirement
  download "https://mono-project.com/download/"

  def self.mono_installed?
    File.exist?("/Library/Frameworks/Mono.framework/Commands/mono")
  end

  env do
    ENV.append_path "PATH", @path
    ENV.append_path "PKG_CONFIG_PATH", "#{@path}/lib/pkgconfig/"
    ENV.append_path "HOMEBREW_LIBRARY_PATHS", "#{@path}/Libraries"
    ENV.append_path "HOMEBREW_INCLUDE_PATHS", "#{@path}/Headers"
  end
end
