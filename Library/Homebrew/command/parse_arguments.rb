require "command/documentation"
require "command/define_command"
require "command/command_options"

module Homebrew
  module Command
    class ParseArguments < CommandOptions
      def initialize(cmd_name)
        super()
        # Get the code block defined in the `define_command` DSL of command
        # `cmd_name`
        code_block = Command.get_cmd_variable_value(cmd_name)
        # Run that code block
        instance_eval(&code_block)
        # Get command line arguments
        @argv_tokens = ARGV.dup.uniq
      end

      # TODO: add error checking support for switches, commands with value, etc
      # will be added in subsequent PRs
      def error_msg
        # Parse the input ARGV arguments and select the invalid option names
        # provided
        invalid_options =
          @argv_tokens
          .select { |arg| /^--/ =~ arg }
          .reject { |arg| @valid_options.map { |opt| opt[:option_name] }.include?(arg) }
        return if invalid_options.empty?
        "Invalid option(s) provided: #{invalid_options.join(" ")}"
      end
    end
  end
end
