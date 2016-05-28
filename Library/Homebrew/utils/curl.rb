require "pathname"

def curl(*args)
  curl = Pathname.new ENV["HOMEBREW_CURL"]
  curl = Pathname.new "/usr/bin/curl" unless curl.exist?
  raise "#{curl} is not executable" unless curl.exist? && curl.executable?

  flags = HOMEBREW_CURL_ARGS
  flags = flags.delete("#") if ARGV.verbose?

  args = [flags, HOMEBREW_USER_AGENT_CURL, *args]
  args << "--verbose" if ENV["HOMEBREW_CURL_VERBOSE"]
  args << "--silent" if !$stdout.tty? || ENV["TRAVIS"]

  safe_system curl, *args
end
