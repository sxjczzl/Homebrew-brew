#:  * `commands` [`--quiet` [`--include-aliases`]]:
#:    Show a list of built-in and external commands.
#:
#:    If `--quiet` is passed, list only the names of commands without the header.
#:    With `--include-aliases`, the aliases of internal commands will be included.

module Homebrew
  module_function

  def commands
    CommandsCommand.call
  end

  class CommandsCommand < Command
    options do
      desc "Show a list of built-in and external commands."
      option "--quiet", "list only the names of commands without the header.", children_options: ["--include-aliases"]
      option "--include-aliases", "the aliases of internal commands will be included."
    end

    def self.call
      # TODO: Put this check_invalid_options() method such that it doesn't have to be here
      check_invalid_options(ARGV.options_only)

      if ARGV.include? "--quiet"
        cmds = internal_commands + external_commands
        cmds += internal_developer_commands
        cmds += HOMEBREW_INTERNAL_COMMAND_ALIASES.keys if ARGV.include? "--include-aliases"
        puts Formatter.columns(cmds.sort)
      else
        # Find commands in Homebrew/cmd
        puts "Built-in commands"
        puts Formatter.columns(internal_commands)

        # Find commands in Homebrew/dev-cmd
        puts
        puts "Built-in developer commands"
        puts Formatter.columns(internal_developer_commands)

        # Find commands in the path
        unless (exts = external_commands).empty?
          puts
          puts "External commands"
          puts Formatter.columns(exts)
        end
      end
    end

    private

    def self.internal_commands
      find_internal_commands HOMEBREW_LIBRARY_PATH/"cmd"
    end

    def self.internal_developer_commands
      find_internal_commands HOMEBREW_LIBRARY_PATH/"dev-cmd"
    end

    def self.external_commands
      paths.each_with_object([]) do |path, cmds|
        Dir["#{path}/brew-*"].each do |file|
          next unless File.executable?(file)
          cmd = File.basename(file, ".rb")[5..-1]
          cmds << cmd unless cmd.include?(".")
        end
      end.sort
    end

    def self.find_internal_commands(directory)
      directory.children.each_with_object([]) do |f, cmds|
        cmds << f.basename.to_s.sub(/\.(?:rb|sh)$/, "") if f.file?
      end
    end
  end
end
