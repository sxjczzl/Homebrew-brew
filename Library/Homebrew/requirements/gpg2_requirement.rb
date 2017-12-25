require "requirement"

class GPG2Requirement < Requirement
  fatal true
  default_formula "gnupg"

  # The aim is to retain support for any version above 2.0.
  satisfy(build_env: false) do
    which_all("gpg").detect do |gpg|
      gpg_short_version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
      next unless gpg_short_version
      gpg_version = Version.create(gpg_short_version.to_s)
      @version = gpg_version
      gpg_version >= Version.create("2.0")
    end
  end

  env do
    # If Homebrew's GPG is installed, prioritise it.
    ENV.prepend_path "PATH", Formula["gnupg"].opt_bin
    ENV.append_path "PATH", "/usr/local/MacGPG2/bin"
  end

  def executable
    which_all("gpg").detect.first
  end

  def version
    Utils.popen_read(executable, "--version")[/\d\.\d/, 0]
  end
end
