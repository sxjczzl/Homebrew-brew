require "command"

describe Homebrew::Command do
  it "initializes correctly" do
    command = Homebrew::Command.new
    command.initialize_variables
    expect(command.valid_options).to eq([])
  end

  it "sets @valid_options correctly" do
    command = Homebrew::Command.new
    command.initialize_variables
    command.option "bar", desc: "go to bar" do
      command.option "foo", desc: "do foo"
    end
    command.option "bar1", desc: "go to bar1"
    expect(command.valid_options).to eq [
      { option_name: "--bar", desc: "go to bar", is_root_option: true,
        child_option_names: ["--foo"] },
      { option_name: "--foo", desc: "do foo", child_option_names: [] },
      { option_name: "--bar1", is_root_option: true, desc: "go to bar1", child_option_names: [] },
    ]
  end

  it "sets error message correctly if invalid options provided" do
    command_options = Homebrew::Command.new
    command_options.initialize_variables
    command_options.command_name = "test_command"
    command_options.description = "This is test_command"
    command_options.option "bar", desc: "go to bar"
    command_options.option "foo", desc: "do foo"
    command_options.option "quiet", desc: "be quiet"
    argv_options = ["--bar1", "--bar2", "--bar", "--foo"]
    expect(command_options
      .error_message(argv_options))
      .to eq "Invalid option(s) provided: --bar1 --bar2"
  end

  it "produces no error message if no invalid options provided" do
    command = Homebrew::Command.new
    command.initialize_variables
    command.option "bar", desc: "go to bar"
    command.option "foo", desc: "do foo"
    command.option "quiet", desc: "be quiet"
    expect(command.error_message(["--quiet", "--bar"])).to eq(nil)
  end
end
