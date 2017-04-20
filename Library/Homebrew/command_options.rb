module Homebrew
  class CommandOptions
    def initialize(command_name)
      @command_name = command_name
      @valid_options = {}
    end

    def option(key, value = "No Description for this Option is Available")
      @valid_options[key] = value
    end

    def check_invalid_options
      invalid_options_by_user = (ARGV.options_only - @valid_options.keys).uniq
      return if invalid_options_by_user.empty?
      invalid_option_pluralize = Formatter.pluralize(invalid_options_by_user.length, "invalid option")
      valid_option_pluralize = Formatter.pluralize(@valid_options.length, "valid option")
      invalid_option_string = "#{invalid_option_pluralize} provided: #{invalid_options_by_user.join " "}"
      if @valid_options.empty?
        odie <<-EOS.undent
          #{invalid_option_string}
          <#{@command_name}> has no valid options

        EOS
      else
        odie <<-EOS.undent
          #{invalid_option_string}
          <#{@command_name}> has only #{valid_option_pluralize}: #{@valid_options.keys.join " "}

              #{@valid_options.map { |k, v| "#{k}:  #{v}" }.join("\n    ")}

        EOS
      end
    end
  end

  def self.options(&block)
    command_name = caller_locations(1, 1).first.label
    command_options = CommandOptions.new(command_name)
    command_options.instance_eval(&block)
    command_options.check_invalid_options
  end
end
