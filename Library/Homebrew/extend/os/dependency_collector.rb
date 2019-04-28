# frozen_string_literal: true

if OS.mac?
  require "extend/os/mac/dependency_collector"
elsif OS.linux?
  require "extend/os/linux/dependency_collector"
elsif OS.cygwin?
  require "extend/os/cygwin/dependency_collector"
end
