require "command/command_options"

module Homebrew
  module Command
    class Documentation < CommandOptions
      # This class will be implemented in a future independent PR

      def initialize(cmd_name) end

      def help_output() end

      def man_output() end
    end
  end
end
