require "utils"
require "resource"

class Gpg
  attr_reader :resource

  # Initially this was just @resource = gpg but that was still producing
  # cache undefined methods, so I noticed our patch setup uses Resource::Patch.new
  # and wondered if that was the issue. Switching to that hasn't solved caching
  # but has introduced `SystemStackError: stack level too deep` when calling Gpg.new()
  def initialize(gpg)
    @resource = Resource::Gpg.new(gpg)
  end

  def url
    resource.url
  end

  def fetch
    resource.fetch
  end

  # This has been repurposed to do GPG verification in another branch for Gpg,
  # but can't test until resolve the ability for download/caching to stop throwing
  # errors, so have left it out here for now with a placeholder text.
  def verify_download_integrity(_fn)
    # GPG isn't verified with a checksum in same way patches/resources are,
    # because tweaking either the GPG signature or the tarball/etc signed
    # result in failure when we verify with GPG_EXECUTABLE.
  end

  # undefined method `cached_download' for "https://ftpmirror.gnu.org/wget/wget-1.18.tar.xz.sig":String
  # /usr/local/Library/Homebrew/cmd/fetch.rb:120:in `fetch_fetchable'
  # /usr/local/Library/Homebrew/cmd/fetch.rb:93:in `fetch_gpg'
  # /usr/local/Library/Homebrew/cmd/fetch.rb:61:in `block in fetch'
  # I tried a variety of custom download mechanisms but eventually returned to
  # borrowing from patch because that obviously works well & avoids introducing
  # completely new code for everyone to have to deal with, but apparently the
  # patch method doesn't work here either. Bleh!
  def cached_download
    resource.cached_download
  end

  def clear_cache
    resource.clear_cache
  end

  def self.find_gpg(executable)
    which_all(executable).detect do |gpg|
      gpg_short_version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
      next unless gpg_short_version
      Version.create(gpg_short_version.to_s) == Version.create("2.0")
    end
  end

  def self.gpg
    find_gpg("gpg")
  end

  def self.gpg2
    find_gpg("gpg2")
  end

  GPG_EXECUTABLE = gpg2 || gpg

  def self.available?
    File.executable?(GPG_EXECUTABLE.to_s)
  end

  def self.create_test_key(path)
    odie "No GPG present to test against!" unless available?

    (path/"batch.gpg").write <<-EOS.undent
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %commit
    EOS
    system GPG_EXECUTABLE, "--batch", "--gen-key", "batch.gpg"
  end
end
