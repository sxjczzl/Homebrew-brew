# frozen_string_literal: true

require "requirements/xcode_requirement"

class SwiftRequirement < Requirement
  satisfy build_env: false do
    next unless @version

    @xcode_requirement = XcodeRequirement.new([xcode_required_version, *tags])
    @xcode_requirement.satisfied?
  end

  def xcode_required_version
    latest = "11.5"
    case @version
    when "5.2" then latest
    when "5.1" then "11.3"
    when "5.0" then "10.2"
    when "4.2" then "10.0"
    when "4.1" then "9.4"
    when "4.0" then "9.2"
    else latest
    end
  end

  undef message

  def message
    <<~EOS
      Swift #{@version} is required to compile this software.

      #{@xcode_requirement.message}
    EOS
  end
end
