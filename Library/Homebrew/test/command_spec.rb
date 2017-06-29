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

  it "tests the option block and @help_output" do
    command = Homebrew::Command.new
    command.initialize_variables
    command.command_name = "test_command"
    command.description = "This is test_command"

    command.option "quiet", desc: "list only the names of commands without the header." do
      command.option "bar", desc: "go to bar" do
        command.option "foo", desc: "do foo" do
          command.option "foo child", desc: "do foo"
        end
        command.option "foo1", desc: "do foo for seconds"
      end
      command.option "include-aliases", desc: "the aliases of internal commands will be included."
    end
    command.option "quiet1", desc: "be quiet"

    command.generate_documentation
    expect(command.help_output).to eq <<-EOS.undent
      brew test_command [--quiet [--bar [--foo [--foo child]] [--foo1]] [--include-aliases]] [--quiet1]:
          This is test_command

          If --quiet is passed, list only the names of commands without the header.
          With --bar, go to bar
          With --foo, do foo
          With --foo child, do foo
          With --foo1, do foo for seconds
          With --include-aliases, the aliases of internal commands will be included.

          If --quiet1 is passed, be quiet
    EOS
      .slice(0..-2)
  end
end
