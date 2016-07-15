module Utils
  def self.git_available?(options = {})
    return @git unless @git.nil?
    version = git_version(options)
    # git version 1.8 or up is required
    @git = !!(version && version >= Version.new("1.8"))
    @git_version = nil unless @git # clean git_version cache if outdated git found
    @git
  end

  def self.git_path
    @git_path ||= Utils.popen_read(
      HOMEBREW_ENV_PATH/"scm/git", "--homebrew=print-path"
    ).chuzzle
  end

  def self.git_version(options = {})
    @git_version ||= begin
      args = []
      args << "--homebrew=fail-on-old-vendor-version" if options[:fail_on_old_vendor_version]
      args << "--version"
      version = Utils.popen_read(HOMEBREW_ENV_PATH/"scm/git", *args).
                      chomp[/git version (\d+(?:\.\d+)*)/, 1]
      Version.new(version) if version
    end
  end

  def self.ensure_git_installed!
    return if git_available? :fail_on_old_vendor_version => true

    oh1 "Installing git"
    system HOMEBREW_BREW_FILE, "vendor-install", "git"

    clear_git_available_cache
    odie "Git must be installed and in your PATH!" unless git_available?
  end

  def self.clear_git_available_cache
    @git = nil
    @git_path = nil
    @git_version = nil
  end
end
