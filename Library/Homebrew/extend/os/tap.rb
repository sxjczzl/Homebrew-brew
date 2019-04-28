# frozen_string_literal: true

if OS.linux?
  require "extend/os/linux/tap"
elsif OS.cygwin?
  require "extend/os/cygwin/tap"
end