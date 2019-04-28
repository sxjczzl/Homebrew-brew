# frozen_string_literal: true

if OS.linux?
  require "extend/os/linux/install"
elsif OS.cygwin?
  require "extend/os/cygwin/install"
end