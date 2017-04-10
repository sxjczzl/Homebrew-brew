module Homebrew
  class OptionsForBrewCommands
    def initialize
      @command_name = ""
      @valid_options = {}
    end

    def command(command)
      @command_name = command
    end

    def option(key, value = "No Description for this Option is Available")
      @valid_options[key] = value
    end

    def check_invalid_options
      invalid_options_by_user = []
      ARGV.options_only.each do |option|
        invalid_options_by_user << option unless @valid_options.key?(option)
      end
      invalid_options_by_user = invalid_options_by_user.uniq
      return if invalid_options_by_user.empty?

      invalid_option_string = "#{Formatter.pluralize(invalid_options_by_user.length, "invalid option")} provided: #{invalid_options_by_user.join " "}"
      if @valid_options.empty?
        odie <<-EOS.undent
          #{invalid_option_string}
          <#{@command_name}> has no valid options

        EOS
      else
        odie <<-EOS.undent
          #{invalid_option_string}
          <#{@command_name}> has only #{Formatter.pluralize(@valid_options.length, "valid option")}: #{@valid_options.keys.join " "}

              #{@valid_options.map { |k, v| "#{k}:  #{v}" }.join("\n    ")}

        EOS
      end
    end
  end

  def self.options(&block)
    options_for_brew_commands = OptionsForBrewCommands.new
    options_for_brew_commands.instance_eval(&block)
  end
end
