if OS.linux?
  require "extend/os/linux/software_spec" 
elsif OS.cygwin?
  require "extend/os/cygwin/software_spec" 
end
