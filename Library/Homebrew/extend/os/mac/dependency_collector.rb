# typed: true
# frozen_string_literal: true

class DependencyCollector
  undef git_dep_if_needed, subversion_dep_if_needed, cvs_dep_if_needed,
        xz_dep_if_needed, unzip_dep_if_needed, bzip2_dep_if_needed,
        parse_swift_spec

  def git_dep_if_needed(tags); end

  def subversion_dep_if_needed(tags)
    Dependency.new("subversion", tags) if MacOS.version >= :catalina
  end

  def cvs_dep_if_needed(tags)
    Dependency.new("cvs", tags)
  end

  def xz_dep_if_needed(tags); end

  def unzip_dep_if_needed(tags); end

  def bzip2_dep_if_needed(tags); end

  private

  def parse_swift_spec(tags)
    min_xcode_version = MacOS::Xcode.minimum_version_for_swift(tags.shift) if tags.first.to_s.match?(/(\d\.)+\d/)

    tags << :build if tags.delete(:build_if_macos)

    if min_xcode_version && Version.new(MacOS::Xcode.latest_version) < Version.new(min_xcode_version)
      # We're on an older OS where we can't update Xcode to get a new enough Swift.
      Dependency.new("swift", tags)
    else
      tags.unshift(min_xcode_version) if min_xcode_version
      XcodeRequirement.new(tags)
    end
  end
end
