module Homebrew
  class Command
    class << self
      attr_reader :command_name, :valid_options, :description, :help_output, :man_output
    end

    def self.initialize
      @valid_options = []
      @description = nil
      @command_name = nil
      @help_output = nil
      @man_output = nil
      @root_options = []
    end

    def self.command(cmd)
      @command_name = cmd
    end

    def self.options(&block)
      initialize
      @parent = nil
      class_eval(&block)
      generate_help_and_manpage_output
    end

    def self.add_valid_option(option, desc)
      valid_option = { option: option, desc: desc, child_options: nil }
      @valid_options.push(valid_option)
    end

    def self.option(key, value, &block)
      if @parent.nil?
        @root_options.push(key)
      end
      unless @parent.nil?
        hash = @valid_options.find { |x| x[:option] == @parent }
        if hash[:child_options].nil?
          hash[:child_options] = [key]
        else
          hash[:child_options].push(key)
        end
      end
      add_valid_option(key, value)
      return unless block_given?
      old_parent = @parent
      @parent = key
      instance_eval(&block)
      @parent = old_parent
    end

    def self.desc(desc)
      if @description.nil?
        @description = desc
      else
        @description = "#{@description}\n#{desc}"
      end
    end

    def self.get_error_message(argv_options_only)
      generate_help_and_manpage_output if @help_output.nil? && @man_output.nil?

      invalid_options = (argv_options_only - @valid_options.map { |x| x[:option] }).uniq
      return nil if invalid_options.empty?
      invalid_option_pluralize = Formatter.pluralize(invalid_options.length, "invalid option")
      invalid_option_string = "#{invalid_option_pluralize} provided: #{invalid_options.join " "}"
      error_message = nil
      if @valid_options.empty?
        error_message = <<-EOS.undent
          #{invalid_option_string}
          The command has no valid options

        EOS
      else
        error_message = <<-EOS.undent
          #{invalid_option_string}
          Correct usage:
          #{@help_output}
        EOS
      end
      error_message
    end

    def self.check_invalid_options(argv_options_only)
      error_message = get_error_message(argv_options_only)
      odie error_message unless error_message.nil?
    end

    def self.option_string(option)
      hash = @valid_options.find { |x| x[:option] == option }
      child_options = hash[:child_options]

      return "[`#{option}`]" if child_options.nil?

      childs_str = ""
      child_options.each do |child_option|
        child_str = option_string(child_option)
        childs_str += child_str
      end
      "[`#{option}` #{childs_str}]"
    end

    def self.desc_string(option, begin_spaces = 4, parent_present = false)
      hash = @valid_options.find { |x| x[:option] == option }
      desc = hash[:desc]
      child_options = hash[:child_options]
      if child_options.nil?
        return " "*begin_spaces + "With `#{option}`, #{desc}\n" if parent_present
        return " "*begin_spaces + "If `#{option}` is passed, #{desc}\n"
      else
        childs_str = ""
        child_options.each do |child_option|
          # TODO: change begin_spaces to begin_spaces+2 if maintainers agree on indenting the descriptions of childs
          child_str = desc_string(child_option, begin_spaces, true)
          childs_str += child_str
        end
        return " "*begin_spaces + "With `#{option}`, #{desc}\n#{childs_str}" if parent_present
        return " "*begin_spaces + "If `#{option}` is passed, #{desc}\n#{childs_str}"
      end
    end

    def self.generate_help_and_manpage_output
      option_str = ""
      desc_str = ""
      @root_options.each do |root_option|
        desc_str += desc_string(root_option)
        option_str += option_string(root_option)
      end
      help_lines = "  " + <<-EOS.undent
        * `#{@command_name}` #{option_str}:
            #{@description}

        #{desc_str}
      EOS
      @man_output = help_lines.slice(0..-2)
      help_lines = help_lines.split("\n")
      help_lines.map! do |line|
        line
          .sub(/^  \* /, "#{Tty.bold}brew#{Tty.reset} ")
          .gsub(/`(.*?)`/, "#{Tty.bold}\\1#{Tty.reset}")
      end.join.strip
      @help_output = help_lines.join("\n")
    end
  end
end
