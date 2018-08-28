if OS.mac?
  require "extend/os/mac/requirements/mono_requirement"
elsif OS.linux?
  require "extend/os/linux/requirements/mono_requirement"
end
