module Homebrew
  class Command
    attr_accessor :command_name, :description
    attr_reader :valid_options, :help_output, :man_output

    def initialize_variables
      @valid_options = []
      @argv_tokens = ARGV.dup.uniq
    end

    def options(&block)
      initialize_variables
      instance_eval(&block)
      generate_documentation
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
        Correct usage:
        #{@help_output}
      EOS
    end

    def generate_documentation
      docs = Documentation.new(@command_name, @description, @valid_options)
      @help_output = docs.help_output
      @man_output = docs.man_output
    end
  end

  class Documentation
    def initialize(cmd_name, cmd_description, cmd_valid_options)
      @cmd_name = cmd_name
      @cmd_description = cmd_description
      @cmd_valid_options = cmd_valid_options
    end

    def man_output
      "\s\s" + <<-EOS.undent.chop
        * `#{@cmd_name}` #{all_options_name_doc}:
            #{@cmd_description}

            #{all_options_desc_doc}
      EOS
    end

    def help_output
      man_output.split("\n").map do |line|
        line
          .sub(/^  \* /, "#{Tty.bold}brew#{Tty.reset} ")
          .gsub(/`(.*?)`/, "#{Tty.bold}\\1#{Tty.reset}")
          .gsub(/<(.*?)>/, "#{Tty.underline}\\1#{Tty.reset}")
      end.join("\n")
    end

    def option_name_doc(option_name)
      child_option_names =
        @cmd_valid_options
        .find { |opt| opt[:option_name] == option_name }[:child_option_names]
        .map { |opt_name| option_name_doc(opt_name) }
        .join(" ")
      return "[`#{option_name}`]" if child_option_names.empty?
      "[`#{option_name}` #{child_option_names}]"
    end

    def all_options_name_doc
      @cmd_valid_options
        .select { |opt| opt[:is_root_option] }
        .map { |opt| opt[:option_name] }
        .map { |opt_name| option_name_doc(opt_name) }
        .join(" ")
    end

    def option_desc_doc(option_name)
      option_hash = @cmd_valid_options.find { |opt| opt[:option_name] == option_name }

      option_desc = <<-EOS.undent
        `#{option_name}`, #{option_hash[:desc]}
      EOS
      if option_hash[:is_root_option]
        option_desc.gsub!(/`#{option_name}`/, 'If \\0 is passed')
      else
        option_desc.gsub!(/`#{option_name}`/, 'With \\0')
      end
      child_option_desc =
        option_hash[:child_option_names]
        .map { |opt_name| option_desc_doc(opt_name) }
        .join("\s\s\s\s")
      return option_desc if child_option_desc.empty?
      "#{option_desc}\s\s\s\s#{child_option_desc}"
    end

    def all_options_desc_doc
      @cmd_valid_options
        .select { |opt| opt[:is_root_option] }
        .map { |opt| opt[:option_name] }
        .map { |opt_name| option_desc_doc(opt_name) }
        .join("\n\s\s\s\s")
    end
  end
end
