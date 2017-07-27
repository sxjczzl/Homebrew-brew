require "command/define_command"

module Homebrew
  module Command
    class RunCommand < DefineCommand
      def initialize(cmd_name)
        # Run the `define_command` DSL for command `cmd_name`
        super(cmd_name)
      end

      # Overrides the DefineCommand::run method
      def run(&code_block)
        # Run the contents of the `run do` DSL which is declared inside
        # the `define_command` DSL
        Homebrew.instance_eval(&code_block)
      end
    end
  end
end
