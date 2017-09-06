require "command/command_options"

module Homebrew
  module Command
    class ParseArguments < CommandOptions
      def initialize(command_name)
        # Run the `define` DSL for command `command_name`
        # and initialize `@valid_options` variable
        super(command_name)
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

      # This method parses the command line arguments when `brew cmd_name`
      # is executed, and throws an error message if any incorrect option
      # is provided
      def parse_arguments_for_error!
        # Get the error message by parsing command line arguments when
        # `brew cmd_name` is executed on the command line
        # If there is no error, proceed with normal execution of command
        return unless error_msg
        # If there is error, quit with the error message
        odie <<-EOS.undent
          #{error_msg}
        EOS
      end

      # Dynamically generate methods that can replace the use of
      # ARGV.include?("option") in the `run do` DSL of a command
      def generate_command_line_parsing_methods
        argv_tokens = @argv_tokens
        # For each valid option, generate a method that checks whether or
        # not that option is provided in the command line arguments
        @valid_options.each do |option|
          option_name = option[:option_name]
          method_name = Command.legal_variable_name(option_name)
          Homebrew.define_singleton_method("#{method_name}?") do
            argv_tokens.include? option_name
          end
        end
      end
    end
  end
end
