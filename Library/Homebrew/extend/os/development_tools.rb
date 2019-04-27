if OS.mac?
  require "extend/os/mac/development_tools"
elsif OS.linux?
  require "extend/os/linux/development_tools"
elsif OS.cygwin?
  require "extend/os/cygwin/development_tools"
end
