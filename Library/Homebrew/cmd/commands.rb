class CommandsBrewCmd < BrewCmdClass
  summary "List available brew subcommands"
  helptext <<EOS

brew commands - #{summary}

  brew commands [--quiet] [--verbose] [--implementation]

Options:
  --quiet            Do not display section headers
  --verbose          Include additional descriptive info
  --include-aliases  Include command aliases (only in --quiet mode)
  --implementation   Include info on each command's implementation
EOS

  def run
    Homebrew.commands
  end
end


module Homebrew
  def commands

    if ARGV.include?("--implementation") || ARGV.include?("--verbose")
      require "command"
    end

    if ARGV.include? "--quiet"
      cmds = internal_commands + external_commands
      cmds += internal_development_commands if ARGV.homebrew_developer?
      cmds += HOMEBREW_INTERNAL_COMMAND_ALIASES.keys if ARGV.include? "--include-aliases"
      puts_columns cmds.sort
    else

      # Find commands in Homebrew/cmd
      puts "Built-in commands"
      display_commands internal_commands

      # Find commands in Homebrew/dev-cmd
      if ARGV.homebrew_developer?
        puts
        puts "Built-in development commands"
        display_commands internal_development_commands
      end

      # Find commands in the path
      unless (exts = external_commands).empty?
        puts
        puts "External commands"
        display_commands exts
      end
    end
  end

  def display_commands(names)
    max_name_len = names.map { |str| str.size }.max
    if ARGV.include? "--implementation"
    format = "%-#{max_name_len}s    %-20s   %s"
    names.each do |name|
      cmd = BrewCmd[name]
      impl_file_display = cmd.internal_cmd? ? "built-in" : cmd.implementation_file
      puts format % [name, cmd.implementation_type, impl_file_display]
    end
    elsif ARGV.include? "--verbose"
      format = "%-#{max_name_len}s    %s"
      names.each do |name|
        cmd = BrewCmd[name]
        puts format % [name, cmd.summary]
      end
    else
      puts_columns names
    end
  end

  def internal_commands
    find_internal_commands HOMEBREW_LIBRARY_PATH/"cmd"
  end

  def internal_development_commands
    find_internal_commands HOMEBREW_LIBRARY_PATH/"dev-cmd"
  end

  def external_commands
    paths.reduce([]) do |cmds, path|
      Dir["#{path}/brew-*"].each do |file|
        next unless File.executable?(file)
        cmd = File.basename(file, ".rb")[5..-1]
        cmds << cmd unless cmd.include?(".")
      end
      cmds
    end.sort
  end

  private

  def find_internal_commands(directory)
    directory.children.reduce([]) do |cmds, f|
      cmds << f.basename.to_s.sub(/\.(?:rb|sh)$/, "") if f.file?
      cmds
    end
  end
end
