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
end
