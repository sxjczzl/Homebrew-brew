if OS.mac?
  require "extend/os/mac/cleaner"
elsif OS.linux?
  require "extend/os/linux/cleaner"
elsif OS.cygwin?
  require "extend/os/cygwin/cleaner"
end
