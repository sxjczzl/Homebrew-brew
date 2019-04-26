# frozen_string_literal: true

if OS.cygwin?
  require "os/cygwin/universal_server"
else
  require "os/default/universal_server"
end
