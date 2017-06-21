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
      desc "Install <formula>."
      argument :formulae
      option "d", "debug", desc: "open an interactive debugging session with access to IRB or a shell inside the temporary build directory."
      option "env", value: "std", desc: "use the standard build environment instead of superenv."
      option "ignore-dependencies", desc: "skip installing any dependencies of any kind. If they are not already present, the formula will probably fail to install."
      option "only-dependencies", desc: "install the dependencies with specified options but do not install the specified formula."
      mutually_exclusive_options "ignore-dependencies", "only-dependencies"
      option "cc", value: "compiler", desc: "attempt to compile using <compiler>. <compiler> should be the name of the compiler's executable, for instance `gcc-4.2` for Apple's GCC 4.2, or `gcc-4.9` for a Homebrew-provided GCC 4.9."
      option "s", "build-from-source", desc: "compile the specified formula from source even if a bottle is provided. Dependencies will still be installed from bottles if they are available."
      option "force-bottle", desc: "install from a bottle if it exists for the current or newest version of macOS, even if it would not normally be used for installation."
      option "devel", desc: "and <formula> defines it, install the development version."
      option "HEAD", desc: "and <formula> defines it, install the HEAD version, aka master, trunk, unstable."
      option "keep-tmp", desc: "the temporary files created during installation are not deleted."
      option "build-bottle", desc: "prepare the formula for eventual bottling during installation."
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
