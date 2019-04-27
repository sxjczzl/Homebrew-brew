if OS.mac?
  require "extend/os/mac/requirements/java_requirement"
elsif OS.linux?
  require "extend/os/linux/requirements/java_requirement"
elsif OS.cygwin?
  require "extend/os/cygwin/requirements/java_requirement"
end
