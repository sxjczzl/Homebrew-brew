# frozen_string_literal: true
 
if OS.cygwin?
   require "os/cygwin/universal_socket"
else
   require "os/default/universal_socket"
end
