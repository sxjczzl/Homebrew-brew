module Homebrew
  module Command
    # This is the main class for the `define_command` DSL method. It declares all
    # the methods used in the `define_command` DSL. The respective methods are
    # overridden by the respective sub-classes that actually use them. The
    # advantage is that no class/sub-class stores any unnecessary variables/state
    # that it will not use.
    class DefineCommand
      def initialize(cmd_name)
        # Get and then run the code block defined in the `define_command` DSL
        # of command `cmd_name`
        instance_eval(&Command.command_variable_value(cmd_name))
      end

      # Overridden by sub-class `Homebrew::Command::Documentation`. The
      # method is called whenever `desc do` DSL is executed inside the
      #  `define_command do` DSL
      def desc(val) end

      # Overridden by sub-class `Homebrew::Command::CommandOptions`. The
      # method is called whenever `option do` DSL is executed inside the
      # `define_command do` DSL
      def option(*vals, &code_block) end

      # Overridden by sub-class `Homebrew::Command::CommandOptions`. The
      # method is called whenever `suboption do` DSL is executed inside
      # the `define_command do` DSL
      def suboption(*vals, &code_block) end

      # Overridden by sub-class `Homebrew::Command::RunCommand`. The
      # method is called whenever `run do` DSL is executed inside the
      # `define_command do` DSL
      def run(&code_block) end
    end
  end
end
