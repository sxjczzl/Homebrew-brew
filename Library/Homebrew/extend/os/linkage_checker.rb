# frozen_string_literal: true

if OS.linux?
  require "extend/os/linux/linkage_checker"
elsif OS.cygwin?
  require "extend/os/cygwin/linkage_checker"
end