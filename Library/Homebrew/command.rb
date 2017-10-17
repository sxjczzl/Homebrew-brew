require "command/parse_arguments"
require "command/run_command"

module Homebrew
  module Command
    module_function

    # This method is run when a `define` DSL is declared anywhere
    def define(name, &block)
      # Set the code block defined in the `define` DSL
      # of command: `name` in its respective variable
      accessor_define(:set, name, &block)
    end

    # This method is run when a user executes "brew `name`" on command line
    def run(name)
      # Parse the command line arguments and quit with an error if any
      # invalid options provided. Otherwise, proceed to running the command
      ParseArguments.new(name).parse_arguments_for_error!
      # Dynamically generate methods that can replace the use of
      # ARGV.include?("option") in the `run do` DSL of command `name`
      ParseArguments.new(name).generate_command_line_parsing_methods
      # Run the contents of the `run do` DSL of command `name`
      RunCommand.new(name)
    end

    # Helper Method for Module:Homebrew:Command
    # Get the legal variable/method name that can be used for the string `name`
    def legal_variable_name(name)
      # Get the legal/valid variable name from `name` by removing the
      # preceeding `--` and converting all `-` to `_`. For e.g. "commands"
      # -> "commands", "gist-logs" -> "gist_logs", "--cache" -> "cache".
      name.gsub(/^--/, "").tr("-", "_")
    end

    # Helper Method for Module:Homebrew:Command
    # :set and :get the `define` DSL code block for command `name`
    def accessor_define(action, name, &block)
      # Infer the respective variable name for command `name` that stores
      # the command's `define` DSL block and :set or :get
      # the value stored in that variable
      command_name = "@#{legal_variable_name(name)}"
      if action == :set
        instance_variable_set(command_name, block)
      elsif action == :get
        instance_variable_get(command_name)
      end
    end
  end
end
