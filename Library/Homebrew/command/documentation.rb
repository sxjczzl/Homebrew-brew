require "command/command_options"

module Homebrew
  module Command
    class Documentation < CommandOptions
      def initialize(cmd_name)
        super()
        @cmd_name = cmd_name
        # Get the code block defined in the `define_command` DSL of command
        # `cmd_name`
        code_block = Command.get_cmd_variable_value(cmd_name)
        # Run that code block
        instance_eval(&code_block)
      end

      # Overrides the DefineCommand::option method
      def option(option_name, &code_block)
        # Create a local instance variable `@option` which is used in
        # `Documentation::desc` and `Documentation::suboption` methods
        @option = option_name
        # Execute the CommandOptions::option method to store `option_name`
        # in `@valid_options` and to execute this method's code block
        # (i.e. `code_block`)
        super
      end

      # Overrides the DefineCommand::suboption method
      def suboption(option_name, &code_block)
        # Create a local instance variable `@suboption` which is used in
        # `Documentation::desc` method
        @suboption = option_name
        # Execute the CommandOptions::suboption method to store `option_name`
        # in `@valid_options` and to execute this method's code block
        # (i.e. `code_block`)
        super
        # Stores the parent-child relationship of option `option_name`, which
        # is used in generating `help` and `man` documentation
        @valid_options
          .find { |opt_h| opt_h[:option_name] == option_name }[:parent_option_name] = @option
      end

      # Overrides the DefineCommand::desc method
      def desc(val)
        # Figure out which DSL method calls this `desc` method and
        # then store the desc relevantly, i.e, is this `desc` method
        # called by the `define_command` DSL or `option` DSL or `suboption` DSL
        caller_method = caller_locations[2].label
        if caller_method == "initialize"
          # Meaning: this `desc` method was called by the `command` DSL, thus,
          # it is the command's description and should be stored in @cmd_desc
          @cmd_desc = val
        elsif caller_method == "option"
          # Meaning: this `desc` method was called by an `option` DSL, thus,
          # it is the desciption of option with name `@option`. Update the
          # description of the relevant option (i.e. `@option`) in @valid_options
          @valid_options
            .find { |opt_h| opt_h[:option_name] == @option }[:desc] = val
        elsif caller_method == "suboption"
          # Meaning: this `desc` method was called by the `suboption` DSL, thus,
          # it is the desciption of option with name `@suboption`. Update the
          # description of the relevant option (i.e. `@suboption`) in @valid_options
          @valid_options
            .find { |opt_h| opt_h[:option_name] == @suboption }[:desc] = val
        end
      end

      # Generates the `brew man` output for command with name `@cmd_name`
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
              #{@cmd_desc}

              #{options_with_desc_doc}
        EOS
      end

      # Generate the `brew --help` output for command with name `@cmd_name`
      def help_output
        # Formatting the man_output
        man_output.split("\n").map do |line|
          line
            .sub(/^  \* /, "#{Tty.bold}brew#{Tty.reset} ")
            .gsub(/`(.*?)`/, "#{Tty.bold}\\1#{Tty.reset}")
            .gsub(/<(.*?)>/, "#{Tty.underline}\\1#{Tty.reset}")
        end.join("\n")
      end

      # Helper method for other methods in this class
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

      # Helper method for other methods in this class
      def option_with_desc_documentation(option_name)
        # Recursively compute, for the option `option_name` (along with all it's child options),
        # the lines of the documentation output that list the option with its desciption
        option_desc = @valid_options
                      .find { |opt| opt[:option_name] == option_name }[:desc]
        option_with_desc_doc = <<-EOS.undent.chop
          #{option_desc}
        EOS
        child_option_with_desc_doc =
          child_option_names(option_name)
          .map { |opt_name| option_with_desc_documentation(opt_name) }
          .join("\s\s\s\s")
        return option_with_desc_doc if child_option_with_desc_doc.empty?
        "#{option_with_desc_doc}\s\s\s\s#{child_option_with_desc_doc}"
      end

      # Helper method for other methods in this class
      def root_option_names
        # returns those options that have no options as parents
        @valid_options.reject { |opt| opt[:parent_option_name] }
                      .map { |opt| opt[:option_name] }
      end

      # Helper method for other methods in this class
      def child_option_names(opt_name)
        # returns those options that have option `opt_name` as a parent
        @valid_options.select { |opt| opt[:parent_option_name] == opt_name }
                      .map { |opt| opt[:option_name] }
      end
    end
  end
end
