require "os/cygwin/pe"

class Pathname
  prepend PEShim
end
