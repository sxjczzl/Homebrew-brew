if OS.mac?
  require "extend/os/mac/requirements/osxfuse_requirement"
elsif OS.linux?
  require "extend/os/linux/requirements/osxfuse_requirement"
elsif OS.cygwin?
  require "extend/os/cygwin/requirements/osxfuse_requirement"
end
