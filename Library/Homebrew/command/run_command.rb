require "command/define_command"

module Homebrew
  module Command
    class RunCommand < DefineCommand
      def initialize(cmd_name)
        super()
        # Get the code block defined in the `define_command` DSL of command
        # `cmd_name`
        code_block = Command.get_cmd_variable_value(cmd_name)
        # Run that code block
        instance_eval(&code_block)
        # Run the contents of the `run do` DSL
        Homebrew.instance_eval(&@run_code_block)
      end

      # Overrides the DefineCommand::run method
      def run(&code_block)
        # store the code block in the `run do` DSL, in a variable
        @run_code_block = code_block
      end
    end
  end
end
