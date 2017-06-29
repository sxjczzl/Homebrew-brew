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
      option_name = "--#{option_name}"
      option_hash[:option_name] = option_name
      option_hash[:parent_name] = @parent_name
      @valid_options.push(option_hash)
      return unless block_given?
      # Before executing the `block`, change @parent_name to
      # `option_name` (because `option_name` is the parent of the options
      # passed inside the `block`)
      parent_temp = @parent_name
      @parent_name = option_name
      instance_eval(&block)
      # After executing the `block`, change `@parent_name` back to
      # original so that the next option at the same hierarchy level as
      # `option_name` in the DSL has the same parent as `option_name`
      @parent_name = parent_temp
    end

    def error_message(argv_tokens = @argv_tokens)
      invalid_options =
        argv_tokens
        .select { |arg| /^--/ =~ arg }
        .reject { |arg| @valid_options.map { |opt| opt[:option_name] }.include?(arg) }
      return if invalid_options.empty?
      "Invalid option(s) provided: #{invalid_options.join " "}"
    end

    def check_for_errors
      return unless error_message
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
    def initialize(cmd_name, cmd_description, valid_options)
      @cmd_name = cmd_name
      @cmd_description = cmd_description
      @valid_options = valid_options
    end

    def man_output
      option_names_doc =
        root_option_names
        .map { |opt_name| option_name_documentation(opt_name) }
        .join(" ")
      options_with_desc_doc =
        root_option_names
        .map { |opt_name| option_with_desc_documentation(opt_name) }
        .join("\n\s\s\s\s")

      "\s\s" + <<-EOS.undent.chop
        * `#{@cmd_name}` #{option_names_doc}:
            #{@cmd_description}

            #{options_with_desc_doc}
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

    def option_name_documentation(option_name)
      child_option_names_doc =
        child_option_names(option_name)
        .map { |opt_name| option_name_documentation(opt_name) }
        .join(" ")
      return "[`#{option_name}`]" if child_option_names_doc.empty?
      "[`#{option_name}` #{child_option_names_doc}]"
    end

    def option_with_desc_documentation(option_name)
      option_desc = @valid_options
                    .find { |opt| opt[:option_name] == option_name }[:desc]
      option_with_desc_doc = <<-EOS.undent
        `#{option_name}`, #{option_desc}
      EOS
      if root_option_names.include?(option_name)
        option_with_desc_doc.gsub!(/`#{option_name}`/, 'If \\0 is passed')
      else
        option_with_desc_doc.gsub!(/`#{option_name}`/, 'With \\0')
      end
      child_option_with_desc_doc =
        child_option_names(option_name)
        .map { |opt_name| option_with_desc_documentation(opt_name) }
        .join("\s\s\s\s")
      return option_with_desc_doc if child_option_with_desc_doc.empty?
      "#{option_with_desc_doc}\s\s\s\s#{child_option_with_desc_doc}"
    end

    def root_option_names
      @valid_options.reject { |opt| opt[:parent_name] }
                    .map { |opt| opt[:option_name] }
    end

    def child_option_names(opt_name)
      @valid_options.select { |opt| opt[:parent_name] == opt_name }
                    .map { |opt| opt[:option_name] }
    end
  end
end
