module Homebrew
  class Command
    attr_reader :command_name, :valid_options, :description

    def initialize
      @valid_options = []
      @description = nil
    end

    def option(key, value = "No description for this option is available", **keyword_args)
      children_options = keyword_args[:children_options]
      @valid_options.push({option: key, desc: value, children_options: children_options})
    end

    def desc(desc)
      if @description.nil?
        @description = desc
      else
        @description = "#{@description}\n#{desc}"
      end
    end

    def get_error_message(argv_options_only)
      valid_options_and_suboptions = {}
      @valid_options.each do |valid_option_hash|
        option_name = valid_option_hash[:option]
        suboptions = valid_option_hash[:children_options]
        if @valid_options.map{|x| x[:children_options]}.flatten.include?(option_name) == false
          valid_options_and_suboptions[option_name] = suboptions
        end
      end
      invalid_options = (argv_options_only - valid_options_and_suboptions.to_a.flatten).uniq
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
        str = ""
        for i in valid_options_and_suboptions
          str = str + "\n  If #{i[0]} is passed, #{@valid_options.find {|hash| hash[:option] == i[0]}[:desc]}"
          next if i[1] == nil
          for children_option in i[1]
            str = str + "\n  With #{children_option}, #{@valid_options.find {|hash| hash[:option] == children_option}[:desc]}"
          end
        end
        error_message = <<-EOS.undent
          #{invalid_option_string}
          The command has only #{valid_option_pluralize}: #{valid_options_and_suboptions.map { |k, v| "[#{k}#{" [#{v.join "][" }]" if v.nil? == false}]" }.join(" ")}
          #{str}

        EOS
      end
      error_message
    end

    def check_invalid_options(argv_options_only)
      error_message = get_error_message(argv_options_only)
      odie error_message unless error_message.nil?
    end

    def options(&block)
      instance_eval(&block)
      check_invalid_options(ARGV.options_only)
    end
  end

  # def self.options(&block)
  #   command_options = CommandOptions.new
  #   command_options.instance_eval(&block)
  #   command_options.check_invalid_options(ARGV.options_only)
  # end
end
