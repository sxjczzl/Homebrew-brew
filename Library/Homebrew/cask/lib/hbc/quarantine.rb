require "development_tools"
module Hbc
  module Quarantine
    module_function

    QUARANTINE_ATTRIBUTE = "com.apple.quarantine".freeze

    def detect(file)
      odebug "Verifying Gatekeeper status of #{file}"

      quarantine_status = !Quarantine.status(file).empty?

      odebug "#{file} is #{quarantine_status ? "quarantined" : "not quarantined"}"

      quarantine_status
    end

    def status(file, command = SystemCommand)
      command.run("/usr/bin/xattr",
                    args:        ["-p", QUARANTINE_ATTRIBUTE, file],
                    print_stderr: false).stdout
    end

    def cask(cask, downloaded_path, command = SystemCommand)
      odebug "Quarantining #{downloaded_path}"
      quarantiner = command.run("/usr/bin/osascript", args: ["#{HOMEBREW_LIBRARY_PATH}/cask/lib/hbc/utils/quarantine.applescript", downloaded_path, cask.url.to_s, cask.homepage.to_s])

      raise CaskError, "when quarantining #{downloaded_path}: #{quarantiner.stderr}" unless quarantiner.success?
    end

    def all(downloaded_path, base_path, command = SystemCommand)
      odebug "Propagating quarantine status of #{downloaded_path}"

      quarantine_status = Quarantine.status(downloaded_path)

      list_of_artifacts = Dir.glob(base_path/"**/*")
      list_of_artifacts.push base_path

      list_of_artifacts.each do |artifact|
        command.run!("/usr/bin/xattr",
                      args: ["-w", QUARANTINE_ATTRIBUTE, quarantine_status, artifact],
                      print_stderr: false)
      end
    end
  end
end
