module Homebrew
  class CheckInvalidOptionsForBrewCommands
    def initialize
      @valid_options = []
    end

    def option(var)
      @valid_options << var
    end

    def check_invalid_options
      invalid_options_by_user = []
      ARGV.options_only.each do |option|
        invalid_options_by_user << option unless @valid_options.include?(option)
      end
      invalid_options_by_user = invalid_options_by_user.uniq
      return if invalid_options_by_user.empty?
      odie <<-EOS.undent
        #{Formatter.pluralize(invalid_options_by_user.length, "Invalid Option")} Provided: #{invalid_options_by_user.join " "}
        #{"Only #{Formatter.pluralize(@valid_options.length, "Option")} Valid: #{@valid_options.join " "}" unless @valid_options.empty?}
      EOS
    end
  end

  def self.options(&block)
    check_invalid_options_for_brew_commands = CheckInvalidOptionsForBrewCommands.new
    check_invalid_options_for_brew_commands.instance_eval(&block)
  end
end
