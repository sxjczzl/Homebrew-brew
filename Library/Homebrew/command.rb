require "command/parse_arguments"
require "command/run_command"

module Homebrew
  module Command
    module_function

    # This method is run when a `define_command do` DSL is declared anywhere
    def define_command(cmd_name, &code_block)
      # Set the code block defined in the `define_command` DSL
      # of command `cmd_name` in its respective variable
      accessor_define_command(:set, cmd_name, &code_block)
    end

    # This method is run when a user executes `brew cmd_name` on command line
    def run_command(cmd_name)
      # Parse the command line arguments and quit with an error if any
      # invalid options provided. Otherwise, proceed to running the command
      parse_arguments!(cmd_name)
      # Dynamically generate methods that can replace the use of
      # ARGV.include?("option") in the `run do` DSL of command `cmd_name`
      ParseArguments.new(cmd_name).generate_command_line_parsing_methods
      # Run the contents of the `run do` DSL of command `cmd_name`
      RunCommand.new(cmd_name)
    end

    # This method parses the command line arguments when `brew cmd_name`
    # is executed, and throws an error message if any incorrect option
    # is provided
    def parse_arguments!(cmd_name)
      # Get the error message by parsing command line arguments when
      # `brew cmd_name` is executed on the command line
      error_msg = ParseArguments.new(cmd_name).error_msg
      # If there is no error, proceed with normal execution of command
      return unless error_msg
      # If there is error, quit with the error message, plus, instructions on
      # correct usage of command `cmd_name`
      odie <<-EOS.undent
        #{error_msg}
      EOS
    end

    # Helper Method
    # Get the lagal variable/method name that can be used for the string `name`
    def legal_variable_name(name)
      # Get the legal/valid variable name from `name` by removing the
      # preceeding `--` and converting all `-` to `_`. For e.g. "commands"
      # -> "commands", "gist-logs" -> "gist_logs", "--cache" -> "cache".
      name.gsub(/^--/, "").tr("-", "_")
    end

    # Helper Method
    # :set and :get the `define_command` DSL code block for command `cmd_name`
    def accessor_define_command(action, cmd_name, &code_block)
      # Infer the respective variable name for command `cmd_name` that stores
      # the command's `define_command` DSL block and :set or :get
      # the value stored in that variable
      command_variable_name = "@#{legal_variable_name(cmd_name)}"
      if action == :set
        instance_variable_set(command_variable_name, code_block)
      elsif action == :get
        instance_variable_get(command_variable_name)
      end
    end
  end
end
