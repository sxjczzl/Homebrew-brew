require "command"

describe Homebrew::Command do
  it "initializes correctly" do
    command_options = Homebrew::Command
    command_options.initialize
    expect(command_options.valid_options).to eq([])
  end

  it "sets valid_options correctly" do
    command_options = Homebrew::Command
    command_options.initialize
    command_options.option name: "bar", desc: "go to bar" do
      command_options.option name: "foo", desc: "do foo"
    end
    command_options.option name: "bar1", desc: "go to bar1"
    expect(command_options.valid_options).to eq [
      { option: "--bar", desc: "go to bar", value: nil, child_options: ["--foo"] },
      { option: "--foo", desc: "do foo", value: nil, child_options: nil },
      { option: "--bar1", desc: "go to bar1", value: nil, child_options: nil },
    ]
  end

  it "sets error message correctly if only one invalid option provided" do
    command_options = Homebrew::Command
    command_options.initialize
    command_options.option name: "bar", desc: "go to bar"
    argv_options = ["--foo"]
    error_message = command_options.get_error_message(argv_options)
    expect(error_message).to \
      include("1 invalid option provided: --foo")
  end

  it "sets error message correctly if more than one invalid options provided" do
    command_options = Homebrew::Command
    command_options.initialize
    command_options.command "test_command"
    command_options.desc "This is test_command"
    command_options.option name: "bar", desc: "go to bar"
    command_options.option name: "foo", desc: "do foo"
    command_options.option name: "quiet", desc: "be quiet"
    argv_options = ["--bar1", "--bar2", "--bar1", "--bar", "--foo"]
    expect(command_options.get_error_message(argv_options)).to eq <<-EOS.undent
      2 invalid options provided: --bar1 --bar2
      Correct usage:
      brew test_command [--bar] [--foo] [--quiet]:
          This is test_command

          If --bar is passed, go to bar

          If --foo is passed, do foo

          If --quiet is passed, be quiet
    EOS
  end

  it "produces no error message if only valid options provided" do
    command_options = Homebrew::Command
    command_options.initialize
    command_options.option name: "bar", desc: "go to bar"
    command_options.option name: "--foo", desc: "do foo"
    command_options.option name: "quiet", desc: "be quiet"
    expect(command_options.get_error_message(["--quiet", "--bar"])).to eq(nil)
  end

  it "tests the option block thoroughly" do
    command_options = Homebrew::Command
    command_options.initialize
    command_options.command "test_command"
    command_options.desc "This is test_command"

    command_options.option name: "quiet", desc: "list only the names of commands without the header." do
      command_options.option name: "bar", desc: "go to bar" do
        command_options.option name: "foo", desc: "do foo" do
          command_options.option name: "foo child", desc: "do foo"
        end
        command_options.option name: "foo1", value: "seconds", desc: "do foo for seconds"
      end
      command_options.option name: "include-aliases", desc: "the aliases of internal commands will be included."
    end
    command_options.option name: "quiet1", value: "days", desc: "be quiet1 for days"

    command_options.generate_help_and_manpage_output
    expect(command_options.help_output).to eq <<-EOS.undent
      brew test_command [--quiet [--bar [--foo [--foo child]] [--foo1=seconds]] [--include-aliases]] [--quiet1=days]:
          This is test_command

          If --quiet is passed, list only the names of commands without the header.
          With --bar, go to bar
          With --foo, do foo
          With --foo child, do foo
          With --foo1=seconds, do foo for seconds
          With --include-aliases, the aliases of internal commands will be included.

          If --quiet1=days is specified, be quiet1 for days
    EOS
      .slice(0..-2)
  end
end
