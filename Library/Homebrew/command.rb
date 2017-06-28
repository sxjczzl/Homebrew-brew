module Homebrew
  class Command
    attr_accessor :command_name, :description
    attr_reader :valid_options

    def initialize_variables
      @valid_options = []
      @argv_tokens = ARGV.dup.uniq
    end

    def options(&block)
      initialize_variables
      instance_eval(&block)
    end

    def option(option_name, **option_hash, &block)
      option_hash[:option_name] = "--#{option_name}"
      option_name = option_hash[:option_name]
      option_hash[:child_option_names] = []
      if @parent_option_name.nil?
        option_hash[:is_root_option] = true
      else
        @valid_options
          .find { |opt| opt[:option_name] == @parent_option_name }[:child_option_names]
          .push(option_name)
      end
      @valid_options.push(option_hash)
      return unless block_given?
      parent_option_name = @parent_option_name
      @parent_option_name = option_name
      instance_eval(&block)
      @parent_option_name = parent_option_name
    end

    def error_message(argv_tokens = @argv_tokens)
      invalid_options =
        argv_tokens.select { |arg| /^--/ =~ arg }
                   .reject { |arg| @valid_options.map { |opt| opt[:option_name] }.include?(arg) }
      return if invalid_options.empty?
      "Invalid option(s) provided: #{invalid_options.join " "}"
    end

    def check_for_errors
      return if error_message.nil?
      odie <<-EOS.undent
        #{error_message}
      EOS
    end
  end
end
