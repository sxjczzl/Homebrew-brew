if OS.mac?
  require "extend/os/mac/diagnostic"
elsif OS.linux?
  require "extend/os/linux/diagnostic"
elsif OS.cygwin?
  require "extend/os/cygwin/diagnostic"
end
