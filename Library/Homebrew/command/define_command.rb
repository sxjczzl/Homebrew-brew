module Homebrew
  module Command
    # This is the main class for the `define` DSL method. It declares all
    # the methods used in the `define` DSL. The respective methods are
    # overridden by the respective sub-classes that actually use them. The
    # advantage is that no class/sub-class stores any unnecessary variables/state
    # that it will not use.
    class DefineCommand
      def initialize(command_name)
        # Get and then run the code block defined in the `define` DSL
        # of command `command_name`
        instance_eval(&Command.accessor_define(:get, command_name))
      end

      # Overridden by sub-class `Homebrew::Command::Documentation`. The
      # method is called whenever `desc do` DSL is executed inside the
      #  `define` DSL
      def desc(val) end

      # Overridden by sub-class `Homebrew::Command::CommandOptions`. The
      # method is called whenever `option do` DSL is executed inside the
      # `define` DSL
      def option(*vals, &code_block) end

      # Overridden by sub-class `Homebrew::Command::CommandOptions`. The
      # method is called whenever `suboption do` DSL is executed inside
      # the `define` DSL
      def suboption(*vals, &code_block) end

      # Overridden by sub-class `Homebrew::Command::RunCommand`. The
      # method is called whenever `run do` DSL is executed inside the
      # `define` DSL
      def run(&code_block) end
    end
  end
end
