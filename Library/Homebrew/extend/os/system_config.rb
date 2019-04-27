if OS.mac?
  require "extend/os/mac/system_config"
elsif OS.linux?
  require "extend/os/linux/system_config"
elsif OS.cygwin?
  require "extend/os/cygwin/system_config"
end
