require "command/define_command"

module Homebrew
  module Command
    class CommandOptions < DefineCommand
      # TODO: add support for switches and options with values, etc.

      def initialize
        # `@valid_options` is an array of hashes. Each hash object represents
        # an option and has the following keys (all with `string` values):
        # `option_name`, `desc`, `parent_option_name`
        @valid_options = []
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
