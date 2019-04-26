# frozen_string_literal: true
require "os/cygwin/pe"

class Pathname
  prepend PEShim
end
