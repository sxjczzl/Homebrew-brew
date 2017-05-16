module Homebrew
  class Command
    attr_reader :command_name, :valid_options, :description

    def initialize
      @valid_options = {}
      @description = nil
    end

    def option(key, value = "No description for this option is available")
      @valid_options[key] = value
    end

    def desc(desc)
      if @description.nil?
        @description = desc
      else
        @description = "#{@description}\n#{desc}"
      end
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
          It has no valid options

        EOS
      else
        error_message = <<-EOS.undent
          #{invalid_option_string}
          It has only #{valid_option_pluralize}: #{@valid_options.keys.join " "}

              #{@valid_options.map { |k, v| "#{k}:  #{v}" }.join("\n    ")}

        EOS
      end
      error_message
    end

    def check_invalid_options(argv_options_only)
      error_message = get_error_message(argv_options_only)
      odie error_message unless error_message.nil?
    end

    def options(&block)
      instance_eval(&block)
      check_invalid_options(ARGV.options_only)
    end
  end

  # def self.options(&block)
  #   command_options = CommandOptions.new
  #   command_options.instance_eval(&block)
  #   command_options.check_invalid_options(ARGV.options_only)
  # end
end
