module Homebrew
  class Command
    attr_accessor :command_name, :description
    attr_reader :valid_options, :help_output, :man_output

    def initialize_variables
      # @valid_options is an array of hashes. Each hash represents an option
      # and has the following keys: `option_name`:string, `desc`:string, `parent_name`:string
      @valid_options = []
      @argv_tokens = ARGV.dup.uniq
    end

    def options(&block)
      initialize_variables
      instance_eval(&block)
    end

    def option(option_name, **option_hash, &block)
      option_name = "--#{option_name}"
      option_hash[:option_name] = option_name
      # @parent_name helps keep track if this `option()` method was called
      # from inside of another `option()` method (and if so, which one)
      option_hash[:parent_name] = @parent_name
      @valid_options.push(option_hash)
      return unless block_given?
      # Before executing the `block`, change @parent_name to
      # `option_name` (because `option_name` is the parent of the options
      # passed inside the `block`)
      parent_temp = @parent_name
      @parent_name = option_name
      instance_eval(&block)
      # Since now we are out of the `block`, change `@parent_name` back to
      # what it was before, so that the next `option` at the same hierarchy level as
      # `option_name` in the `options` DSL has the same parent info as `option_name`
      @parent_name = parent_temp
    end

    def error_message(argv_tokens = @argv_tokens)
      # parse the input arguments and select the invalid option names
      invalid_options =
        argv_tokens
        .select { |arg| /^--/ =~ arg }
        .reject { |arg| @valid_options.map { |opt| opt[:option_name] }.include?(arg) }
      return if invalid_options.empty?
      "Invalid option(s) provided: #{invalid_options.join " "}"
    end

    def check_for_errors
      return unless error_message
      generate_documentation
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
      # Generate first line of the command's documentation
      # that specifies relationships between different options
      option_names_doc =
        root_option_names
        .map { |opt_name| option_name_documentation(opt_name) }
        .join(" ")
      # Generate rest of the lines of the command's documentation
      # that lists each option along with its description
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
      # Formatting the documentation for improved display on the user's screen
      # for `--help`
      man_output.split("\n").map do |line|
        line
          .sub(/^  \* /, "#{Tty.bold}brew#{Tty.reset} ")
          .gsub(/`(.*?)`/, "#{Tty.bold}\\1#{Tty.reset}")
          .gsub(/<(.*?)>/, "#{Tty.underline}\\1#{Tty.reset}")
      end.join("\n")
    end

    def option_name_documentation(option_name)
      # Recursively compute the first line of the documentation output
      # part for the option `option_name` (along with all it's child options)
      child_option_names_doc =
        child_option_names(option_name)
        .map { |opt_name| option_name_documentation(opt_name) }
        .join(" ")
      return "[`#{option_name}`]" if child_option_names_doc.empty?
      "[`#{option_name}` #{child_option_names_doc}]"
    end

    def option_with_desc_documentation(option_name)
      # Recursively compute, for the option `option_name` (along with all it's child options),
      # the lines of the documentation output that list the option with its desciption
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
