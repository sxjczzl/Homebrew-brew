# frozen_string_literal: true
 
require "extend/ENV"
require "socket"

class UniversalSocket
  def self.open
    socket = UNIXSocket.open(ENV["HOMEBREW_ERROR_PIPE"], &:recv_io)
    socket.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
    if block_given?
      yield socket
    else
      return socket
    end
  end
end
