# frozen_string_literal: true

require "extend/ENV"
require "fcntl"
require "socket"
require "os/universal_server"

class UniversalServer
  def self.open
    server = TCPServer.open("127.0.0.1", 0)
    ENV["HOMEBREW_ERROR_PIPE"] = server.addr[1].to_s

    return server unless block_given?

    yield server
  end
end
