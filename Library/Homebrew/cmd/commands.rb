#:  * `commands` [`--quiet` [`--include-aliases`]]:
#:    Show a list of built-in and external commands.
#:
#:    If `--quiet` is passed, list only the names of commands without the header.
#:    With `--include-aliases`, the aliases of internal commands will be included.

module Homebrew
  module_function

  def commands
    # TODO: goal is to no longer require def commands at all
    CommandsCommand.call
  end

  class CommandsCommand < Command
    options do
      command "commands"
      desc "Show a list of built-in and external commands."
      optional_arg :formulae
      optional_arg :formulae1
      compulsory_arg :car
      compulsory_arg :bus
      option option: "quiet", desc: "list only the names of commands without the header.", switch: "n" do
        option option: "include-aliases", desc: "the aliases of internal commands will be included."
        option option: "foo", desc: "do foo"
        option switch: "t", desc: "scrub the cache, removing downloads for even the latest versions of formulae."
      end
      option switch: "s", desc: "scrub the cache, removing downloads for even the latest versions of formulae."
      option option: "prune", value: "days", desc: "remove all cache files older than <days>."
      option option: "prune1", value: "days", desc: "remove all cache files older than <days>."
    end

    def self.call
      # TODO: Put this check_for_errors() method such that it doesn't have to be here
      check_for_errors

      if quiet?
        cmds = internal_commands + external_commands
        cmds += internal_developer_commands
        cmds += HOMEBREW_INTERNAL_COMMAND_ALIASES.keys if include_aliases?
        puts Formatter.columns(cmds.sort)
      else
        # Find commands in Homebrew/cmd
        puts "Built-in commands"
        puts Formatter.columns(internal_commands)

        # Find commands in Homebrew/dev-cmd
        puts <<-EOS.undent

          Built-in developer commands
          #{Formatter.columns(internal_developer_commands)}
        EOS

        # Find commands in the path
        return if (exts = external_commands).empty?
        puts <<-EOS.undent

          External commands
          #{Formatter.columns(exts)}
        EOS
      end
    end

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
