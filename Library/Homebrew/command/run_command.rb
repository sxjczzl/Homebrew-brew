require "command/define_command"

module Homebrew
  module Command
    class RunCommand < DefineCommand
      def initialize(command_name)
        # Run the `define` DSL for command `command_name`
        super(command_name)
      end

      # Overrides the DefineCommand::run method
      def run(&code_block)
        # Run the contents of the `run do` DSL which is declared inside
        # the `define` DSL
        Homebrew.instance_eval(&code_block)
      end
    end
  end
end
