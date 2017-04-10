module Homebrew
  class OptionsForBrewCommands
    def initialize
      @valid_options = {}
    end

    def option(key, value)
      @valid_options[key] = value
    end

    def check_invalid_options
      invalid_options_by_user = []
      ARGV.options_only.each do |option|
        invalid_options_by_user << option unless @valid_options.key?(option)
      end
      invalid_options_by_user = invalid_options_by_user.uniq
      return if invalid_options_by_user.empty?
      odie <<-EOS.undent
        #{Formatter.pluralize(invalid_options_by_user.length, "Invalid Option")} Provided: #{invalid_options_by_user.join " "}
        #{"Only #{Formatter.pluralize(@valid_options.length, "Option")} Valid: #{@valid_options.keys.join " "}" unless @valid_options.empty?}

            #{@valid_options.map { |k, v| "#{k}:  #{v}" }.join("\n    ")}

      EOS
    end
  end

  def self.options(&block)
    options_for_brew_commands = OptionsForBrewCommands.new
    options_for_brew_commands.instance_eval(&block)
  end
end
