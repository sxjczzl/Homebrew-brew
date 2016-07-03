require "requirement"

class GPGRequirement < Requirement
  fatal true
  default_formula "gnupg2"

  satisfy(:build_env => false) { gpg2 || gpg1 }

  # Homebrew installs GnuPG 1.x as `gpg` but this may change in future.
  # MacGPG2/GPGTools installs GnuPG 2.0.x as a vanilla `gpg` symlink
  # pointing to `gpg2`. Ensure we're not using unexpected gpg version.
  def gpg1
    which_all("gpg").detect do |gpg|
      gpg_short_version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
      next unless gpg_short_version
      Version.new(gpg_short_version.to_s) == Version.new("1.4")
    end
  end

  def gpg2
    which_all("gpg2").detect do |gpg2|
      gpg2_short_version = Utils.popen_read(gpg2, "--version")[/\d\.\d/, 0]
      next unless gpg2_short_version
      # For now, to give upstreams time to adjust, only support 2.0.x
      # rather than the 2.1.x "modern" series.
      Version.new(gpg2_short_version.to_s) == Version.new("2.0")
    end
  end
end
