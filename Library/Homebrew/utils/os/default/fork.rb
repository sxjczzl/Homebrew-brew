# frozen_string_literal: true
 
module Utils
  def self.fork_child_initialize(server)
    server.close
  end

  def self.socket_send_fd(socket, write)
    socket.send_io(write)
    socket.close
  end

  def self.read_from_child(socket, read)
    return read.read
  end
end
