module Homebrew
  class Command
    attr_reader :command_name, :valid_options, :description, :help_output, :man_output

    def self.initialize
      @valid_options = []
      @description = nil
      # TODO: set the @command_name dynamically
      @command_name = "commands"
      @help_output = nil
      @man_output = nil
    end

    def self.options(&block)
      initialize
      @parent = nil
      instance_eval(&block)
      generate_help_and_manpage_output
      puts "valid_options: ", @valid_options
      # check_invalid_options(ARGV.options_only)
    end

    # def self.option(key, value = "No description for this option is available", **keyword_args)
    #   children_options = keyword_args[:children_options]
    #   @valid_options.push({option: key, desc: value, children_options: children_options})
    # end

    def self.add_valid_option(option, desc)
      valid_option = {:option => option, :desc => desc, :children_options => nil}
      @valid_options.push(valid_option)
    end

    def self.option(key, value, &block)
      # puts "-->lol",key,@parent,"-->end lol"
      if @parent != nil
        hash = @valid_options.find { |x| x[:option] == @parent }
        if hash[:children_options] == nil
          hash[:children_options] = [key]
        else
          hash[:children_options].push(key)
        end
      end
      add_valid_option(key, value)
      if block.nil?
        # @parent = nil
        a = 1
      else
        old_parent = @parent
        @parent = key
        instance_eval(&block)
        @parent = old_parent
      end
    end

    def self.desc(desc)
      if @description.nil?
        @description = desc
      else
        @description = "#{@description}\n#{desc}"
      end
    end

    def self.get_error_message(argv_options_only)
      invalid_options = (argv_options_only - @valid_options.map{ |x| x[:option]}).uniq
      return nil if invalid_options.empty?
      invalid_option_pluralize = Formatter.pluralize(invalid_options.length, "invalid option")
      valid_option_pluralize = Formatter.pluralize(@valid_options.length, "valid option")
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

    def self.generate_help_and_manpage_output
      valid_options_and_suboptions = {}
      @valid_options.each do |valid_option_hash|
        option_name = valid_option_hash[:option]
        suboptions = valid_option_hash[:children_options]
        if @valid_options.map{|x| x[:children_options]}.flatten.include?(option_name) == false
          valid_options_and_suboptions[option_name] = suboptions
        end
      end        
      help_lines = "  " + <<-EOS.undent
        * `#{@command_name}` #{valid_options_and_suboptions.map { |k, v| "[`#{k}`#{" [`#{v.join "`][`" }`]" if v.nil? == false}]" }.join(" ")}:
            #{@description}

      EOS
      for i in valid_options_and_suboptions
        help_lines += "    " + <<-EOS.undent
          If `#{i[0]}` is passed, #{@valid_options.find {|hash| hash[:option] == i[0]}[:desc]}
        EOS
        next if i[1] == nil
        for children_option in i[1]
          help_lines += "    " + <<-EOS.undent
              With `#{children_option}`, #{@valid_options.find {|hash| hash[:option] == children_option}[:desc]}
          EOS
        end
      end
      @man_output = help_lines
      help_lines = help_lines.split("\n")
      help_lines.map! do |line|
        line
            .sub(/^  \* /, "#{Tty.bold}brew#{Tty.reset} ")
            .gsub(/`(.*?)`/, "#{Tty.bold}\\1#{Tty.reset}")
      end.join.strip
      @help_output = help_lines.join("\n")
    end

    def self.help_output
      @help_output
    end

    def self.man_output
      @man_output
    end
  end
end
