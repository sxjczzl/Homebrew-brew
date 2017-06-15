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
      @optional_trailing_args = []
      @compulsory_trailing_args = []
      @argv = ARGV
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

    def self.add_valid_option(option_hash)
      @valid_options.push(option_hash)
    end

    def self.switches
      @valid_options.select { |h| /^-(?!-)/ =~ h[:option] || h[:switch] }
                    .map { |h| h[:switch] || h[:option] }
    end

    def self.option(*args, **option_hash, &block)
      if args.length == 2
        if args[0].length != 1
          raise ArgumentError, <<-EOS.undent
            Developer's Error. Incorrect option params in options block
            Format: switch, option, ...
            switch should be of length = 1
          EOS
        end
        option_hash[:switch] = args[0]
        option_hash[:option] = args[1]
      elsif args.length == 1
        if args[0].length == 1
          option_hash[:switch] = args[0]
        else
          option_hash[:option] = args[0]
        end
      else
        raise ArgumentError, <<-EOS.undent
          Developer's Error. Incorrect # of arguments for option in options block
        EOS
      end

      option_hash[:option] = "--#{option_hash[:option]}" if option_hash[:option]
      option_hash[:switch] = "-#{option_hash[:switch]}" if option_hash[:switch]
      if option_hash[:option].nil?
        option_hash[:option] = option_hash[:switch]
        option_hash[:switch] = nil
      end
      option_name = option_hash[:option]
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
      add_valid_option(option_hash)
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
        @description = <<-EOS.undent
          #{@description}
          #{desc}
        EOS
                             .strip
      end
    end

    def self.argv_invalid_options_passed(argv_options_only)
      argv_options_only = argv_options_only.select { |arg| /^--/ =~ arg }
      argv_options_only = argv_options_only.uniq
      valid_option_names =
        @valid_options
        .map { |option_hash| option_hash[:option] }

      argv_options_only
        .reject { |opt| valid_option_names.include?(opt.split("=", 2)[0]) }
        .map { |opt| opt.split("=", 2)[0] }
    end

    def self.argv_options_without_value_passed(argv_options_only)
      argv_options_only = argv_options_only.select { |arg| /^--/ =~ arg }
      valid_options_with_values =
        @valid_options
        .select { |option_hash| option_hash[:value] }

      options_without_value =
        argv_options_only
        .select { |opt| valid_options_with_values.map { |x| x[:option] }.include?(opt.split("=", 2)[0]) }
        .select do |opt|
          (opt.include?("=") && opt.split("=", 2)[1].empty?) ||
            (!opt.include?("=") && (ARGV[ARGV.index(opt)+1].nil? ||
                          ARGV[ARGV.index(opt)+1].start_with?("-")))
        end
      options_without_value.map do |opt|
        opt_name = opt.split("=", 2)[0]
        opt_value = @valid_options.find { |x| x[:option] == opt_name }[:value]
        [opt_name, opt_value]
      end
    end

    def self.argv_invalid_switches_passed(argv_options_only)
      argv_options_only.select { |arg| /^-(?!-)/ =~ arg }
                       .map { |s| s[1..-1] }
                       .select { |s| !(s.split("") - switches.map { |sw| sw[1..-1] }).empty? }
                       .map { |s| "-#{s}" }
    end

    def self.trailing_args_error
      # test case: brew commands --lol lo --prune pop --fo po
      valid_options_with_values =
        @valid_options
        .select { |option_hash| option_hash[:value] }
        .map { |option_hash| option_hash[:option] }

      trailing_args =
        [nil, *@argv]
        .each_cons(2)
        .select do |prev_arg, arg|
          (prev_arg.nil? && !arg.start_with?("-")) ||
            (!prev_arg.nil? && !valid_options_with_values.include?(prev_arg))
        end
        .map { |_prev_arg, arg| arg }
        .select { |arg| !arg.start_with?("-") }

      return if trailing_args.empty?
      if (@compulsory_trailing_args+@optional_trailing_args).include?(:formulae)
        invalid_formulas =
          trailing_args
          .select { |arg| Formulary.loader_for(arg).class.to_s == "Formulary::NullLoader" }
        return "Invalid formula name(s): #{invalid_formulas.join(" ")}" unless invalid_formulas.empty?
      else
        return "Invalid trailing argument(s): #{trailing_args.join(" ")}"
      end
    end

    def self.get_error_message(argv_options_only)
      generate_help_and_manpage_output if @help_output.nil? && @man_output.nil?

      argv_invalid_options = argv_invalid_options_passed(argv_options_only)
      argv_options_without_value = argv_options_without_value_passed(argv_options_only)
      argv_invalid_switches = argv_invalid_switches_passed(argv_options_only)
      invalid_options_switches = argv_invalid_options + argv_invalid_switches

      return if invalid_options_switches.empty? && argv_options_without_value.empty?

      invalid_opt_str = Formatter.pluralize(invalid_options_switches.length, "invalid option")
      invalid_opt_str = "#{invalid_opt_str} provided: #{invalid_options_switches.join " "}"
      trailing_args_err = trailing_args_error
      opt_without_value_str =
        argv_options_without_value
        .map { |k, v| "#{k} requires a value <#{v}>" }.join("\n")
      error_msg = <<-EOS.undent
        #{invalid_opt_str unless invalid_options_switches.empty?}\
        #{"\n" if !invalid_options_switches.empty? && !opt_without_value_str.empty?}\
        #{opt_without_value_str unless opt_without_value_str.empty?}\
        #{"\n"+trailing_args_err unless trailing_args_err.nil?}
      EOS

      <<-EOS.undent
        #{error_msg}
        Correct usage:
        #{@help_output}
      EOS
    end

    def self.check_for_errors
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
      "[`#{option}=`<#{value}> #{childs_str}]"
    end

    def self.desc_string(option, begin_spaces = 4, parent_present = false)
      hash = @valid_options.find { |x| x[:option] == option }
      desc = hash[:desc]
      child_options = hash[:child_options]
      option_value = hash[:value]

      output = <<-EOS.undent
        `#{option}`, #{desc}
      EOS
      if parent_present
        output = output.gsub(/`#{option}`/, 'With \\0')
      elsif option_value.nil?
        output = output.gsub(/`#{option}`/, 'If \\0 is passed')
      else
        output = output.gsub(/`#{option}`/, 'If \\0 is specified')
      end
      if option_value
        output = output
                 .gsub(/`#{option}`/, "`#{option}=`<#{option_value}>")
      end
      if hash[:switch]
        output = output.gsub(/`#{option}`/, "\\0 or `#{hash[:switch]}`")
      end
      unless child_options.nil?
        childs_str = child_options.map do |co|
          desc_string(co, begin_spaces, true)
        end.join("\s\s\s\s")
        output = <<-EOS.undent
          #{output}\s\s\s\s#{childs_str}
        EOS
                       .chop
      end
      output
    end

    def self.generate_help_and_manpage_output
      option_str = @root_options.map do |ro|
        option_string(ro)
      end.join(" ")
      desc_str = @root_options.map do |ro|
        desc_string(ro)
      end.join("\n\s\s\s\s")
      unless @optional_trailing_args.empty?
        opt_trailing_str = " [<" + @optional_trailing_args.map { |a| a }
                           .join(">] [<") + ">]"
      end
      unless @compulsory_trailing_args.empty?
        comp_trailing_str = " <" + @compulsory_trailing_args.map { |a| a }
                            .join("> <") + ">"
      end

      help_lines = "\s\s" + <<-EOS.undent
        * `#{@command_name}` #{option_str}#{opt_trailing_str}#{comp_trailing_str}:
            #{@description}

            #{desc_str}
      EOS
                   .chop
      @man_output = help_lines
      help_lines = help_lines.split("\n")
      help_lines.map! do |line|
        line
          .sub(/^  \* /, "#{Tty.bold}brew#{Tty.reset} ")
          .gsub(/`(.*?)`/, "#{Tty.bold}\\1#{Tty.reset}")
          .gsub(/<(.*?)>/, "#{Tty.underline}\\1#{Tty.reset}")
      end
      @help_output = help_lines.join("\n")
    end

    def self.optional_arg(arg)
      @optional_trailing_args.push(arg)
    end

    def self.compulsory_arg(arg)
      @compulsory_trailing_args.push(arg)
    end
  end
end
