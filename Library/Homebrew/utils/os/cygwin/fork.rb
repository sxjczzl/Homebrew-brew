# frozen_string_literal: true
 
module Utils
  def self.fork_child_initialize(server) end

  def self.socket_send_fd(socket, write) end

  def self.read_from_child(socket, read)
    if socket.nil?
      data = read.read
    else
      data = socket.read
      socket.close
    end
    return data # rubocop:disable Style/RedundantReturn
  end
end
