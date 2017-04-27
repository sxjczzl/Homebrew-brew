# To run this test file: 'brew tests --only=command_options'

require "command_options"

def get_valid_options(cmd)
  # parses the #{cmd}.rb file and extracts the valid options defined in the options DSL
  content = File.readlines "cmd/#{cmd}.rb"
  inside_options_block = false
  valid_options = {}
  content.each do |line|
    if inside_options_block == true
      if line.include? "option"
        line_splitted = line.scan(/"([^"]*)"/)
        option = line_splitted.first.first
        option_description = line_splitted.last.first
        valid_options[option] = option_description
      end
      break if line.include? "end"
    end
    inside_options_block = true if line.include? "options do"
  end
  return valid_options
end

describe Homebrew::CommandOptions do
  describe "brew commands", :integration_test do
    cmd = "commands"

    it "checks correctness of initialize() method" do
      command_options = Homebrew::CommandOptions.new
      expect(command_options.command_name).to eq(nil)
      expect(command_options.valid_options).to eq({})

      command_options = Homebrew::CommandOptions.new("test command")
      expect(command_options.command_name).to eq("test command")
      expect(command_options.valid_options).to eq({})
    end

    it "checks correctness of option() method" do
      command_options = Homebrew::CommandOptions.new
      command_options.option("--bar")
      command_options.option("--foo", "do foo")
      command_options.option("--quiet", "be quiet")
      expect(command_options.valid_options).to eq({ "--foo"=>"do foo", "--quiet"=>"be quiet",
        "--bar"=>"No description for this option is available" })
    end

    it "test # 1: runs correctly if no option is provided" do
      expect { brew "commands" }
        .to output(/Built-in commands/).to_stdout
        .and be_a_success
    end

    valid_options = get_valid_options(cmd)
    valid_options.each do |option, _desc|
      it "test # 2: runs correctly if any 1 correct option is provided" do
        expect { system("brew commands #{option}") }
          .to output(/--cache/).to_stdout_from_any_process
      end
    end

    it "test # 3: runs correctly if all correct options are provided" do
      expect { system("brew commands #{valid_options.keys.join " "}") }
        .to output(/--cache/).to_stdout_from_any_process
    end

    it "test # 4: returns error if 1 incorrect option is provided" do
      expect { system("brew commands --quietee") }
        .to output(<<-MESSAGE.undent).to_stderr_from_any_process
		  Error: 1 invalid option provided: --quietee
		  <#{cmd}> has only 2 valid options: --quiet --include-aliases

		      --quiet:  List only the names of commands without the header
		      --include-aliases:  The aliases of internal commands will be included

		MESSAGE
    end

    it "test # 5: returns error if more than 1 incorrect options are provided" do
      expect { system("brew commands --quietee --qute --foo1 --foo2") }
        .to output(<<-MESSAGE.undent).to_stderr_from_any_process
		  Error: 4 invalid options provided: --quietee --qute --foo1 --foo2
		  <#{cmd}> has only 2 valid options: --quiet --include-aliases

		      --quiet:  List only the names of commands without the header
		      --include-aliases:  The aliases of internal commands will be included

		MESSAGE
    end

    # The following Test # 6 can be used for other cmds as well
    all_argv_options = [["--foo"],
                        ["--bar", "--bar1", "--bar2"],
                        ["--quietee", "--qute", "--foo1", "--foo2", "--quiet"]]
    all_argv_options.each do |argv_options|
      it "test # 6: returns error if incorrect option(s) provided" do
        invalid_options_by_user = (argv_options - valid_options.keys).uniq
        invalid_option_pluralize = Formatter.pluralize(invalid_options_by_user.length, "invalid option")
        valid_option_pluralize = Formatter.pluralize(valid_options.length, "valid option")
        invalid_option_string = "#{invalid_option_pluralize} provided: #{invalid_options_by_user.join " "}"

        expect = expect { system("brew commands #{argv_options.join " "}") }
        if valid_options.empty?
          expect.to output(<<-MESSAGE.undent).to_stderr_from_any_process
            Error: #{invalid_option_string}
            <#{cmd}> has no valid options

          MESSAGE
        else
          expect.to output(<<-MESSAGE.undent).to_stderr_from_any_process
            Error: #{invalid_option_string}
            <#{cmd}> has only #{valid_option_pluralize}: #{valid_options.keys.join " "}

                #{valid_options.map { |k, v| "#{k}:  #{v}" }.join("\n    ")}

          MESSAGE
        end
      end
    end
  end
end
