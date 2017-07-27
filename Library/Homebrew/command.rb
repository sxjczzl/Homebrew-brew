require "command/parse_arguments"
require "command/documentation"
require "command/run_command"

module Homebrew
  module Command
    module_function

    # This method is run when a `define_command do` DSL is declared anywhere
    def define_command(cmd_name, &code_block)
      # Infer the variable name from `cmd_name`
      cmd_var_name = cmd_variable_name(cmd_name)
      # Dynamically create this variable as an instance variable of
      # Module:Homebrew::Command and set its value to `code_block`
      # (i.e. the block of code passed into this `define_command` DSL)
      instance_variable_set(cmd_var_name, code_block)
    end

    # This method is run when a user executes `brew cmd_name` on command line
    def run_command(cmd_name)
      # Parse the command line arguments and quit with an error if any
      # invalid options provided. Otherwise, proceed to running the command
      parse_arguments!(cmd_name)
      # Run the contents of the `run do` DSL of command `cmd_name`
      RunCommand.new(cmd_name)
    end

    def manpage_documentation(cmd_name)
      # Get the `brew man` output for command `cmd_name`
      Documentation.new(cmd_name).man_output
    end

    def help_documentation(cmd_name)
      # Get the `brew --help` output for command `cmd_name`
      Documentation.new(cmd_name).help_output
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
        Correct usage:
        #{help_documentation(cmd_name)}
      EOS
    end

    # Helper Method
    # Infer the variable name from `cmd_name`
    def cmd_variable_name(cmd_name)
      # Infer the variable name from `cmd_name`: First convert the command's
      # name (i.e. `cmd_name`) to it's legal variable name. For e.g.
      # "commands" -> "commands", "gist-logs" -> "gist_logs", "--cache" ->
      # "cache". Then, append "_command" to the variable name (because of
      # the convention used in naming these variable names)
      "@#{cmd_name.gsub(/^--/, "").tr("-", "_")}_command"
    end

    # Helper Method
    # Fetches the value (i.e. code block of `define_command do` DSL) stored in
    # the relevant command's variable. For example, for the `cmd_name`
    # "commands", return the value of the variable `@commands_command`
    def get_cmd_variable_value(cmd_name)
      # Infer the variable name from `cmd_name`
      cmd_var_name = cmd_variable_name(cmd_name)
      # Return the value stored in this variable
      instance_variable_get(cmd_var_name)
    end
  end
end
