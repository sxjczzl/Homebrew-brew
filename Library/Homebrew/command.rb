module Homebrew
  class Command
    class << self
      attr_reader :command_name, :valid_options, :description, :help_output,
        :man_output
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
      build_methods_from_options
    end

    def self.build_methods_from_options
      @valid_options.each do |hash|
        option_name = hash[:option]
        option_name = option_name.gsub(/^--/, "").tr("-", "_")
        Command.define_singleton_method("#{option_name}?") do
          ARGV.include? "--#{option_name.tr("_", "-")}"
        end
      end
    end

    def self.add_valid_option(option, desc, value)
      valid_option = { option: option, desc: desc, value: value, child_options: nil }
      @valid_options.push(valid_option)
    end

    def self.option(**hash_args, &block)
      option_name = hash_args[:name]
      option_desc = hash_args[:desc]
      option_value = hash_args[:value]
      option_name = "--#{option_name}"
      if @parent.nil?
        @root_options.push(option_name)
      else
        hash = @valid_options.find { |x| x[:option] == @parent }
        if hash[:child_options].nil?
          hash[:child_options] = [option_name]
        else
          hash[:child_options].push(option_name)
        end
      end
      add_valid_option(option_name, option_desc, option_value)
      return unless block_given?
      old_parent = @parent
      @parent = option_name
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

    def self.argv_invalid_options_passed(argv_options_only)
      argv_options_only = argv_options_only.uniq
      valid_option_names =
        @valid_options
        .map { |option_hash| option_hash[:option] }

      argv_options_only
        .reject { |opt| valid_option_names.include?(opt.split("=", 2)[0]) }
        .map { |opt| opt.split("=", 2)[0] }
    end

    def self.argv_options_without_value_passed(argv_options_only)
      valid_options_with_values =
        @valid_options
        .select { |option_hash| option_hash[:value] }
        .map { |option_hash| option_hash[:option] }

      options_without_value =
        argv_options_only
        .select do |opt|
          valid_options_with_values.include?(opt.split("=", 2)[0]) &&
            (!opt.include?("=") || opt.split("=", 2)[1] == "")
        end
      options_without_value.map do |opt|
        opt_name = opt.split("=", 2)[0]
        opt_value = @valid_options.find { |x| x[:option] == opt_name }[:value]
        [opt_name, opt_value]
      end
    end

    def self.get_error_message(argv_options_only)
      generate_help_and_manpage_output if @help_output.nil? && @man_output.nil?

      argv_invalid_options = argv_invalid_options_passed(argv_options_only)
      argv_options_without_value = argv_options_without_value_passed(argv_options_only)

      return if argv_invalid_options.empty? && argv_options_without_value.empty?
      invalid_option_pluralize = Formatter.pluralize(argv_invalid_options.length, "invalid option")
      invalid_option_string = "#{invalid_option_pluralize} provided: #{argv_invalid_options.join " "}"
      unless argv_options_without_value.empty?
        invalid_option_string = <<-EOS.undent
          #{invalid_option_string}
          #{argv_options_without_value.map { |k, v| "#{k} requires a value <#{v}>" }.join("\n")}
        EOS
      end
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

    def self.check_invalid_options
      error_message = get_error_message(ARGV.options_only)
      odie error_message unless error_message.nil?
    end

    def self.option_string(option)
      hash = @valid_options.find { |x| x[:option] == option }
      child_options = hash[:child_options]

      # return "[`#{option}`]" if child_options.nil?
      value = hash[:value]
      if child_options.nil?
        return "[`#{option}`]" if value.nil?
        return "[`#{option}=`<#{value}>]"
      end

      childs_str = child_options.map do |co|
        option_string(co)
      end.join(" ")
      return "[`#{option}` #{childs_str}]" if value.nil?
      return "[`#{option}=`<#{value}> #{childs_str}]"
    end

    def self.desc_string(option, begin_spaces = 4, parent_present = false)
      hash = @valid_options.find { |x| x[:option] == option }
      desc = hash[:desc]
      child_options = hash[:child_options]
      if child_options.nil?
        # return " "*begin_spaces + "With `#{option}`, #{desc}\n" if parent_present
        # return " "*begin_spaces + "If `#{option}` is passed, #{desc}\n"
        option_value = hash[:value]
        if parent_present
          return " "*begin_spaces + "With `#{option}`, #{desc}\n" if option_value.nil?
          return " "*begin_spaces + "With `#{option}=`<#{option_value}>, #{desc}\n"
        else
          return " "*begin_spaces + "If `#{option}` is passed, #{desc}\n" if option_value.nil?
          return " "*begin_spaces + "If `#{option}=`<#{option_value}> is specified, #{desc}\n"
        end
      else
        # TODO: change begin_spaces to begin_spaces+2 if maintainers agree on indenting the descriptions of childs
        childs_str = child_options.map do |co|
          desc_string(co, begin_spaces, true)
        end.join("")
        return " "*begin_spaces + "With `#{option}`, #{desc}\n#{childs_str}" if parent_present
        return " "*begin_spaces + "If `#{option}` is passed, #{desc}\n#{childs_str}"
      end
    end

    def self.generate_help_and_manpage_output
      option_str = @root_options.map do |ro|
        option_string(ro)
      end.join(" ")
      desc_str = @root_options.map do |ro|
        desc_string(ro)
      end.join("\n")
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
          .gsub(/<(.*?)>/, "#{Tty.underline}\\1#{Tty.reset}")
      end.join.strip
      @help_output = help_lines.join("\n")
    end
  end
end
