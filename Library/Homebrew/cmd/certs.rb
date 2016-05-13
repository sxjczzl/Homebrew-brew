#:  * `certs` [`--force-curl`]:
#:    You should really write more documentation up here Dom.

module Homebrew
  BREWED_CURL = Pathname.new(HOMEBREW_PREFIX/"opt/curl")
  BREWED_OPENSSL = Pathname.new(HOMEBREW_PREFIX/"opt/openssl")
  BREWED_LIBRESSL = Pathname.new(HOMEBREW_PREFIX/"opt/libressl")
  BREWED_GNUTLS = Pathname.new(HOMEBREW_PREFIX/"opt/gnutls")

  def certs
    # Needs further investigation, just a rough guess currently that Apple
    # isn't regularly updating certificates for Mountain Lion or less now.
    if OS.mac? && MacOS.version <= :mountain_lion || OS.linux? || ARGV.include?("--force-curl")
      use_brew_curl
    elsif OS.mac? && MacOS.version >= :mavericks
      use_postinstall
    else
      raise UsageError
    end
  end

  def use_brew_curl
    if BREWED_CURL.exist?
      HOMEBREW_CACHE.mkpath
      Dir.chdir HOMEBREW_CACHE
      quiet_system BREWED_CURL/"libexec/mk-ca-bundle.pl", "-q", "-f", "cert.pem"

      if BREWED_OPENSSL.exist? || BREWED_GNUTLS.exist?
        Pathname.new(HOMEBREW_PREFIX/"etc/openssl").mkpath
        FileUtils.cp "cert.pem", Pathname.new(HOMEBREW_PREFIX/"etc/openssl")
      end
      if BREWED_LIBRESSL.exist?
        Pathname.new(HOMEBREW_PREFIX/"etc/libressl").mkpath
        FileUtils.cp "cert.pem", Pathname.new(HOMEBREW_PREFIX/"etc/libressl")
      end
    else
      odie <<-EOS.undent
        This command requires Homebrew's curl to be installed for this operating
        system. Please install it with:
          `brew install curl`
      EOS
    end
  end

  def use_postinstall
    quiet_system "brew", "postinstall", "openssl" if BREWED_OPENSSL.exist?
    quiet_system "brew", "postinstall", "libressl" if BREWED_LIBRESSL.exist?
    quiet_system "brew", "postinstall", "gnutls" if BREWED_GNUTLS.exist?
  end
end
