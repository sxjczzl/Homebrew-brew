module Homebrew
  def self.check_invalid_options(&block)
    check_invalid_options_for_brew_commands = CheckInvalidOptionsForBrewCommands.new
    check_invalid_options_for_brew_commands.instance_eval(&block)
  end
end
