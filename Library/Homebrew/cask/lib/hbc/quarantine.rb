module Hbc
  module Quarantine
    module_function

    QUARANTINE_ATTRIBUTE = "com.apple.quarantine".freeze

    def detect(file, command = SystemCommand)
      odebug "Verifying Gatekeeper status of #{file}"

      quarantine_status = !command.run("/usr/bin/xattr",
                                      args:         ["-p", QUARANTINE_ATTRIBUTE, file],
                                      print_stderr: false).stdout.empty?

      odebug "Quarantine status of #{file}: #{quarantine_status}"

      quarantine_status
    end

    def all(cask, downloaded_path, command = SystemCommand)
      odebug "Quarantining #{downloaded_path}"
      command.run!("/usr/bin/swift", args: ["#{HOMEBREW_LIBRARY_PATH}/cask/lib/hbc/utils/quarantine.swift", downloaded_path, cask.url.to_s])
    end
  end
end
