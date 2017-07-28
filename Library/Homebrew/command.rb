require "command/parse_arguments"
require "command/run_command"

module Homebrew
  module Command
    module_function

    # This method is run when a `define_command do` DSL is declared anywhere
    def define_command(cmd_name, &code_block)
      # Infer the variable name from `cmd_name`. Then, dynamically
      # create this variable as an instance variable of
      # Module:Homebrew::Command and set its value to `code_block`
      # (i.e. the block of code passed into this `define_command` DSL)
      instance_variable_set("@#{legal_variable_name(cmd_name)}", code_block)
    end

    # This method is run when a user executes `brew cmd_name` on command line
    def run_command(cmd_name)
      # Dynamically generate methods that can replace the use of
      # ARGV.include?("option") in the `run do` DSL of command `cmd_name`
      ParseArguments.new(cmd_name).generate_command_line_parsing_methods
      # Parse the command line arguments and quit with an error if any
      # invalid options provided. Otherwise, proceed to running the command
      parse_arguments!(cmd_name)
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
    def legal_variable_name(name)
      # Get the legal/valid variable name from `name`. For e.g.
      # "commands" -> "commands", "gist-logs" -> "gist_logs", "--cache" ->
      # "cache".
      name.gsub(/^--/, "").tr("-", "_")
    end

    # Helper Method
    # Fetches the value (i.e. code block of `define_command do` DSL) stored in
    # the relevant command's variable. For example, for the `cmd_name`
    # "commands-temp", return the value of the variable `@commands_temp`
    def command_variable_value(cmd_name)
      # Infer the variable name from `cmd_name` and return the value stored
      # in that variable
      instance_variable_get("@#{legal_variable_name(cmd_name)}")
    end
  end
end
