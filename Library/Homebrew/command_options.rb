module Homebrew
  class CommandOptions
    attr_reader :command_name, :valid_options

    def initialize(command_name)
      @command_name = command_name
      @valid_options = {}
    end

    def option(key, value = "No description for this option is available")
      @valid_options[key] = value
    end

    def get_error_message(argv_options_only)
      invalid_options = (argv_options_only - @valid_options.keys).uniq
      return nil if invalid_options.empty?
      invalid_option_pluralize = Formatter.pluralize(invalid_options.length, "invalid option")
      valid_option_pluralize = Formatter.pluralize(@valid_options.length, "valid option")
      invalid_option_string = "#{invalid_option_pluralize} provided: #{invalid_options.join " "}"
      error_message = nil
      if @valid_options.empty?
        error_message = <<-EOS.undent
          #{invalid_option_string}
          <#{@command_name}> has no valid options

        EOS
      else
        error_message = <<-EOS.undent
          #{invalid_option_string}
          <#{@command_name}> has only #{valid_option_pluralize}: #{@valid_options.keys.join " "}

              #{@valid_options.map { |k, v| "#{k}:  #{v}" }.join("\n    ")}

        EOS
      end
      error_message
    end

    def check_invalid_options(argv_options_only)
      error_message = get_error_message(argv_options_only)
      odie error_message unless error_message.nil?
    end
  end

  def self.options(&block)
    command_name = caller_locations(1, 1).first.label
    command_options = CommandOptions.new(command_name)
    command_options.instance_eval(&block)
    command_options.check_invalid_options(ARGV.options_only)
  end
end
