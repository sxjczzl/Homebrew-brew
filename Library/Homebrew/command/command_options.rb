require "command/define_command"

module Homebrew
  module Command
    class CommandOptions < DefineCommand
      # This class builds the `@valid_options` variable, which is used by
      # two of it's sub-classes: `Homebrew::Command::ParseArguments` and
      # `Homebrew::Command::Documentation`.
      # TODO: add support for switches and options with values, etc.

      def initialize(cmd_name)
        # `@valid_options` is an array of hashes. Each hash object represents
        # an option and has the following keys (all with `string` values):
        # `option_name`, `desc`, `parent_option_name`
        @valid_options = []
        # Run the `define_command` DSL for command `cmd_name`
        super(cmd_name)
      end

      # Overrides the DefineCommand::option method
      def option(option_name, &code_block)
        @valid_options.push(option_name: option_name)
        instance_eval(&code_block)
      end

      # Overrides the DefineCommand::suboption method
      def suboption(option_name, &code_block)
        @valid_options.push(option_name: option_name)
        instance_eval(&code_block)
      end
    end
  end
end
