# Andrew's in-progress version of brew.rb that uses BrewCmd objects

std_trap = trap("INT") { exit! 130 } # no backtrace thanks

require "pathname"
HOMEBREW_LIBRARY_PATH = Pathname.new(__FILE__).realpath.parent.join("Homebrew")
$:.unshift(HOMEBREW_LIBRARY_PATH.to_s)
require "global"
require "command"

if ARGV == %w[--version] || ARGV == %w[-v]
  puts "Homebrew #{Homebrew.homebrew_version_string}"
  puts "Homebrew/homebrew-core #{Homebrew.core_tap_version_string}"
  exit 0
end

if OS.mac? && MacOS.version < "10.6"
  abort <<-EOABORT.undent
    Homebrew requires Snow Leopard or higher. For Tiger and Leopard support, see:
    https://github.com/mistydemeo/tigerbrew
  EOABORT
end

def require?(path)
  require path
rescue LoadError => e
  # HACK: ( because we should raise on syntax errors but
  # not if the file doesn't exist. TODO make robust!
  raise unless e.to_s.include? path
end

begin
  trap("INT", std_trap) # restore default CTRL-C handler

  # Parse inputs
  empty_argv = ARGV.empty?
  help_flag_list = %w[-h --help --usage -? help]
  help_flag = false
  cmd = nil

  ARGV.dup.each_with_index do |arg, i|
    if help_flag && cmd
      break
    elsif help_flag_list.include? arg
      help_flag = true
    elsif !cmd
      cmd = ARGV.delete_at(i)
    end
  end

  # Display general usage if no args, or a help flag without a command
  if cmd.nil?
    require "cmd/help"
    if empty_argv
      $stderr.puts ARGV.usage
    else
      puts ARGV.usage
    end
    exit ARGV.any? ? 0 : 1
  end

  # Add contributed commands to PATH before checking.
  Dir["#{HOMEBREW_LIBRARY}/Taps/*/*/cmd"].each do |tap_cmd_dir|
    ENV["PATH"] += "#{File::PATH_SEPARATOR}#{tap_cmd_dir}"
  end

  # Add SCM wrappers.
  ENV["PATH"] += "#{File::PATH_SEPARATOR}#{HOMEBREW_ENV_PATH}/scm"

  # Look up and run given command
  cmd_obj = BrewCmd[cmd]
  if cmd_obj.nil?
    BrewCmdLoader.lookup_well_known_tap_commands(cmd)
    cmd_obj = BrewCmd[cmd]
  end
  if cmd_obj.nil?
    onoe "Unknown command: #{cmd}"
    exit 1
  end

  if help_flag && !cmd_obj.handles_help_itself?
    cmd_obj.display_help
  else
    cmd_obj.run
  end
  exit Homebrew.failed? ? 1 : 0

rescue FormulaUnspecifiedError
  abort "This command requires a formula argument"
rescue KegUnspecifiedError
  abort "This command requires a keg argument"
rescue UsageError
  onoe "Invalid usage"
  abort ARGV.usage
rescue SystemExit => e
  onoe "Kernel.exit" if ARGV.verbose? && !e.success?
  $stderr.puts e.backtrace if ARGV.debug?
  raise
rescue Interrupt => e
  $stderr.puts # seemingly a newline is typical
  exit 130
rescue BuildError => e
  report_analytics_exception(e)
  e.dump
  exit 1
rescue RuntimeError, SystemCallError => e
  report_analytics_exception(e)
  raise if e.message.empty?
  onoe e
  $stderr.puts e.backtrace if ARGV.debug?
  exit 1
rescue Exception => e
  report_analytics_exception(e)
  onoe e
  if !cmd_obj.nil? && cmd_obj.internal_cmd?
    $stderr.puts "#{Tty.white}Please report this bug:"
    $stderr.puts "    #{Tty.em}#{OS::ISSUES_URL}#{Tty.reset}"
  end
  $stderr.puts e.backtrace
  exit 1
else
  exit 1 if Homebrew.failed?
end
