# frozen_string_literal: true

if OS.mac?
  require "os/mac/universal_server"
elsif OS.linux?
  require "os/linux/universal_server"
elsif OS.cygwin?
  require "os/cygwin/universal_server"
end
