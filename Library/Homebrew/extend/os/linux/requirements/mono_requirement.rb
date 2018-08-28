require "requirement"

class MonoRequirement < Requirement
  download "https://mono-project.com/download/"

  satisfy(build_env: false) { self.class.mono_installed? }

  def self.mono_installed?
    File.exist?("/usr/bin/mono")
  end
end
