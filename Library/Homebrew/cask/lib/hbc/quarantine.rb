require "development_tools"
module Hbc
  module Quarantine
    module_function

    QUARANTINE_ATTRIBUTE = "com.apple.quarantine".freeze

    # @private
    def swift
      @swift ||= DevelopmentTools.locate("swift")
    end

    def available?
      status = !swift.nil?
      odebug "Quarantine is #{status ? "available" : "not available"}."
      !swift.nil?
    end

    def detect(file)
      odebug "Verifying Gatekeeper status of #{file}"

      quarantine_status = Quarantine.status(file)

      odebug "Quarantine status of #{file}: #{quarantine_status}"

      !quarantine_status.empty?
    end

    def status(file, command = SystemCommand)
      command.run("/usr/bin/xattr",
                    args:        ["-p", QUARANTINE_ATTRIBUTE, file],
                    print_stderr: false).stdout
    end

    def cask(cask, downloaded_path, command = SystemCommand)
      odebug "Quarantining #{downloaded_path}"
      command.run!(swift, args: ["#{HOMEBREW_LIBRARY_PATH}/cask/lib/hbc/utils/quarantine.swift", downloaded_path, cask.url.to_s, cask.homepage.to_s])
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
