old_trap = trap("INT") { exit! 130 }

require "global"
require "debrew"
require "fcntl"
require "socket"
require "os/universal_socket"

begin
  error_pipe = UniversalSocket.open

  trap("INT", old_trap)

  formula = ARGV.resolved_formulae.first
  formula.extend(Debrew::Formula) if ARGV.debug?
  formula.run_post_install
rescue Exception => e # rubocop:disable Lint/RescueException
  error_pipe.puts e.to_json
  error_pipe.close
  exit! 1
end
