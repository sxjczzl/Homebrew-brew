# frozen_string_literal: true
 
if OS.cygwin?
  require "utils/os/cygwin/fork.rb"
else
  require "utils/os/default/fork.rb"
end

