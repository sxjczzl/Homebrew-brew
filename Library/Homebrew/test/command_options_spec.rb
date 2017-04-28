require "command_options"

describe Homebrew::CommandOptions do
  describe "Tests for CommandOptions() class: " do
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

    it "checks full error message if more than 1 incorrect options are provided" do
      command_options = Homebrew::CommandOptions.new("test command")
      command_options.option("--bar")
      command_options.option("--foo", "do foo")
      command_options.option("--quiet", "be quiet")
      error_message = command_options.get_error_message(["--bar1", "--bar2", "--bar1", "--bar", "foo"])
      expected_error_message = <<-EOS.undent
      3 invalid options provided: --bar1 --bar2 foo
      <test command> has only 3 valid options: --bar --foo --quiet

          --bar:  No description for this option is available
          --foo:  do foo
          --quiet:  be quiet

      EOS
      expect(error_message).to eq(expected_error_message)
    end

    it "checks no error if all correct options are provided" do
      command_options = Homebrew::CommandOptions.new("test command")
      command_options.option("--bar")
      command_options.option("--foo", "do foo")
      command_options.option("--quiet", "be quiet")
      error_message = command_options.get_error_message(["--quiet", "--bar"])
      expect(error_message).to eq(nil)
    end
  end
end
