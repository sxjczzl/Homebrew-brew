module Hbc
  module Quarantine
    module_function

    def all(cask, downloaded_path, command = SystemCommand)
      odebug "Quarantining #{downloaded_path}"
      command.run!("/usr/bin/swift", args: ["#{HOMEBREW_LIBRARY_PATH}/cask/lib/hbc/utils/quarantine.swift", downloaded_path, cask.url.to_s])
    end
  end
end
