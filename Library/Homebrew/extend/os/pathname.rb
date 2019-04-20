if OS.mac?
  require "extend/os/mac/extend/pathname"
elsif OS.cygwin?
   require "extend/os/cygwin/extend/pathname"
elsif OS.linux?
  require "extend/os/linux/extend/pathname"
end
