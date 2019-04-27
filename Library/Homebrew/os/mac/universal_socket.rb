# frozen_string_literal: true

require "extend/ENV"
require "socket"

class UniversalSocket
  def self.open
    socket = UNIXSocket.open(ENV["HOMEBREW_ERROR_PIPE"], &:recv_io)
    socket.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

    return socket unless block_given?

    yield socket
  end
end
