require "command_options"

describe Homebrew::CommandOptions do
  describe "Tests for CommandOptions() class: " do
    it "checks correctness of initialize() method" do
      command_options = Homebrew::CommandOptions.new("test command")
      expect(command_options.command_name).to eq("test command")
      expect(command_options.valid_options).to eq({})
    end

    it "checks correct setting of valid_options" do
      command_options = Homebrew::CommandOptions.new("test command")
      command_options.option("--bar")
      command_options.option("--foo", "do foo")
      command_options.option("--quiet", "be quiet")
      expect(command_options.valid_options).to eq({ "--foo"=>"do foo", "--quiet"=>"be quiet",
        "--bar"=>"No description for this option is available" })
    end

    it "checks error message if invalid option(s) are provided" do
      command_options = Homebrew::CommandOptions.new("test command")
      command_options.option("--bar")
      error_message = command_options.get_error_message(["foo"])
      expect(error_message).to include("<test command> has only 1 valid option: --bar")

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

    it "checks no error if all valid options are provided" do
      command_options = Homebrew::CommandOptions.new("test command")
      command_options.option("--bar")
      command_options.option("--foo", "do foo")
      command_options.option("--quiet", "be quiet")
      error_message = command_options.get_error_message(["--quiet", "--bar"])
      expect(error_message).to eq(nil)
    end
  end
end
