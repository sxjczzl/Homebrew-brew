# frozen_string_literal: true
 
require "extend/ENV"
require "socket"

class UniversalSocket
  def self.open
     port = ENV["HOMEBREW_ERROR_PIPE"].to_i
     socket = TCPSocket.new('127.0.0.1', port)
     if block_given?
        yield socket
     else
        return socket
     end
  end
end
