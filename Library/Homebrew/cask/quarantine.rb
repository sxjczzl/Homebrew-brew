# frozen_string_literal: true

require "development_tools"
module Cask
  module Quarantine
    module_function

    QUARANTINE_ATTRIBUTE = "com.apple.quarantine"

    QUARANTINE_SCRIPT = (HOMEBREW_LIBRARY_PATH/"cask/utils/quarantine.swift").freeze

    XATTR = (HOMEBREW_LIBRARY_PATH/"cask/utils/xattr.swift").freeze

    # @private
    def swift
      @swift ||= DevelopmentTools.locate("swift")
    end

    def check_quarantine_support
      odebug "Checking quarantine support"

      if swift.nil?
        odebug "Swift is not available on this system."
        :no_swift
      else
        api_check = system_command(swift,
                                   args:         [QUARANTINE_SCRIPT],
                                   print_stderr: false)

        xattr_check = system_command(swift,
                                     args:         [XATTR],
                                     print_stderr: false)

        case api_check.exit_status
        when 5
          odebug "This feature requires the macOS 10.10 SDK or higher."
          :no_quarantine
        when 2
          odebug "Quarantine is available."
        else
          odebug "Unknown support status"
          :unknown
        end

        case xattr_check.exit_status
        when 2
          odebug "xattr script is available."
          :quarantine_available
        else
          odebug "xattr script is unsupported"
          :no_xattr
        end
      end
    end

    def available?
      @status ||= check_quarantine_support

      @status == :quarantine_available
    end

    def detect(file)
      return if file.nil?

      odebug "Verifying Gatekeeper status of #{file}"

      quarantine_status = !status(file).empty?

      odebug "#{file} is #{quarantine_status ? "quarantined" : "not quarantined"}"

      quarantine_status
    end

    def status(file)
      system_command(swift,
                     args:         [XATTR, "get", QUARANTINE_ATTRIBUTE, file],
                     print_stderr: false).stdout.rstrip
    end

    def toggle_no_translocation_bit(attribute)
      fields = attribute.split(";")

      # Fields: status, epoch, download agent, event ID
      # Let's toggle the app translocation bit, bit 8
      # http://www.openradar.me/radar?id=5022734169931776

      fields[0] = (fields[0].to_i(16) | 0x0100).to_s(16).rjust(4, "0")

      fields.join(";")
    end

    def release!(download_path: nil)
      return unless detect(download_path)

      odebug "Releasing #{download_path} from quarantine"

      quarantiner = system_command(swift,
                                   args:         [XATTR, "remove", QUARANTINE_ATTRIBUTE, file],
                                   print_stderr: false)

      return if quarantiner.success?

      raise CaskQuarantineReleaseError.new(download_path, quarantiner.stderr)
    end

    def cask!(cask: nil, download_path: nil, action: true)
      return if cask.nil? || download_path.nil?

      return if detect(download_path)

      odebug "Quarantining #{download_path}"

      quarantiner = system_command(swift,
                                   args:         [
                                     QUARANTINE_SCRIPT,
                                     download_path,
                                     cask.url.to_s,
                                     cask.homepage.to_s,
                                   ],
                                   print_stderr: false)

      return if quarantiner.success?

      case quarantiner.exit_status
      when 2
        raise CaskQuarantineError.new(download_path, "Insufficient parameters")
      else
        raise CaskQuarantineError.new(download_path, quarantiner.stderr)
      end
    end

    def propagate(from: nil, to: nil)
      return if from.nil? || to.nil?

      raise CaskError, "#{from} was not quarantined properly." unless detect(from)

      odebug "Propagating quarantine from #{from} to #{to}"

      quarantine_status = toggle_no_translocation_bit(status(from))

      resolved_paths = Pathname.glob(to/"**/*", File::FNM_DOTMATCH).select(&:exist?)

      system_command!("/usr/bin/xargs",
                      args:  [
                        "-0",
                        "--",
                        "/bin/chmod",
                        "-h",
                        "u+w",
                      ],
                      input: resolved_paths.join("\0"))

      quarantiner = system_command("/usr/bin/xargs",
                                   args:         [
                                     "-0",
                                     "--",
                                     swift,
                                     XATTR,
                                     "set",
                                     QUARANTINE_ATTRIBUTE,
                                     quarantine_status,
                                   ],
                                   input:        resolved_paths.join("\0"),
                                   print_stderr: false)

      return if quarantiner.success?

      raise CaskQuarantinePropagationError.new(to, quarantiner.stderr)
    end
  end
end
