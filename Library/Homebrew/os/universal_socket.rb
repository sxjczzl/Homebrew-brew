# frozen_string_literal: true

if OS.mac?
  require "os/mac/universal_socket"
elsif OS.linux?
  require "os/linux/universal_socket"
elsif OS.cygwin?
  require "os/cygwin/universal_socket"
end
