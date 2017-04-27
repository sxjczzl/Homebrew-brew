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

def random_invalid_options(valid_options, array_length)
  invalid_options = []
  while true do
    rand = ("a".."z").to_a.sample(5).join
    invalid_options.push(rand) if valid_options.include?(rand) == false && invalid_options.include?(rand) == false
    return invalid_options if invalid_options.length == array_length
  end
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
      expect { brew cmd }
        .to output.to_stdout
        .and be_a_success
    end

    valid_options = get_valid_options(cmd)
    valid_options.each do |option, _desc|
      it "test # 2: runs correctly if any 1 correct option is provided" do
        expect { system("brew #{cmd} #{option}") }
          .to output.to_stdout_from_any_process
      end
    end

    it "test # 3: runs correctly if all correct options are provided" do
      expect { system("brew #{cmd} #{valid_options.keys.join " "}") }
        .to output.to_stdout_from_any_process
    end

    it "test # 4: returns error if 1 incorrect option is provided" do
      invalid_option = "--#{random_invalid_options(valid_options, 1)[0]}"
      expect { system("brew #{cmd} #{invalid_option}") }
        .to output(/invalid option provided/).to_stderr_from_any_process
    end

    it "test # 5: returns error if more than 1 incorrect options are provided" do
      invalid_options = random_invalid_options(valid_options, 3)
      expect { system("brew #{cmd} --#{invalid_options.join " --"}") }
        .to output(/invalid options provided/).to_stderr_from_any_process
    end
  end
end
