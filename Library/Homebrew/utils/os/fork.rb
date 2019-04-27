# frozen_string_literal: true

if OS.mac?
  require "utils/os/mac/fork.rb"
elsif OS.linux?
  require "utils/os/linux/fork.rb"
elsif OS.cygwin?
  require "utils/os/cygwin/fork.rb"
end
