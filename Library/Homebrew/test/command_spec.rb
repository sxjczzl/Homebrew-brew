require "command"

describe Homebrew::Command do
  it "initializes correctly" do
    command = Homebrew::Command
    command.initialize
    expect(command.valid_options).to eq([])
  end

  it "sets @valid_options correctly" do
    command = Homebrew::Command
    command.initialize
    command.option "bar", desc: "go to bar" do
      command.option "foo", desc: "do foo"
    end
    command.option "bar1", desc: "go to bar1"
    expect(command.valid_options).to eq [
      { option: "--bar", desc: "go to bar", child_options: ["--foo"] },
      { option: "--foo", desc: "do foo" },
      { option: "--bar1", desc: "go to bar1" },
    ]
  end

  it "sets error message correctly if only one invalid option provided" do
    command = Homebrew::Command
    command.initialize
    command.option "bar", desc: "go to bar"
    argv_options = ["--foo"]
    error_message = command.get_error_message(argv_options)
    expect(error_message).to \
      include("1 invalid option provided: --foo")
  end

  it "sets error message correctly if more than one invalid options provided" do
    command_options = Homebrew::Command
    command_options.initialize
    command_options.cmd_name "test_command"
    command_options.desc "This is test_command"
    command_options.option "bar", desc: "go to bar"
    command_options.option "foo", desc: "do foo"
    command_options.option "quiet", desc: "be quiet"
    argv_options = ["--bar1", "--bar2", "--bar1", "--bar", "--foo"]
    expect(command_options.get_error_message(argv_options)).to eq <<-EOS.undent
      2 invalid options provided: --bar1 --bar2
    EOS
  end

  it "produces no error message if no invalid options provided" do
    command = Homebrew::Command
    command.initialize
    command.option "bar", desc: "go to bar"
    command.option "foo", desc: "do foo"
    command.option "quiet", desc: "be quiet"
    expect(command.get_error_message(["--quiet", "--bar"])).to eq(nil)
  end

  it "tests the option method block thoroughly" do
    command = Homebrew::Command
    command.initialize
    command.cmd_name "test_command"
    command.desc "This is test_command"

    command.option "quiet", desc: "list only the names of commands without the header." do
      command.option "bar", desc: "go to bar" do
        command.option "foo", desc: "do foo" do
          command.option "foo child", desc: "do foo"
        end
        command.option "foo1", value: "seconds", desc: "do foo for seconds"
      end
      command.option "include-aliases", desc: "the aliases of internal commands will be included."
    end
    command.option "quiet1", value: "days", desc: "be quiet1 for days"

    command.generate_help_and_manpage_output
    expect(command.help_output).to eq <<-EOS.undent
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

  it "sets @command_name correctly" do
    command = Homebrew::Command
    command.initialize
    command.cmd_name "test_command"
    expect(command.command_name).to eq("test_command")
  end

  it "checks error message when a (expected) value for an option is not provided" do
    command = Homebrew::Command
    command.options do
      command.cmd_name "commands"
      command.desc "Show a list of built-in and external commands."
      command.option "quiet", desc: "list only the names of commands without the header." do
        command.option "include-aliases", desc: "the aliases of internal commands will be included."
      end
      command.option "prune", value: "days", desc: "remove all cache files older than <days>."
      command.option "prune1", value: "days", desc: "remove all cache files older than <days>."
    end
    argv_options = ["--foo", "--pop", "--quiet", "--prune=", "--prune1", "20", "--lol=20"]
    expect(command.get_error_message(argv_options)).to eq <<-EOS.undent
      3 invalid options provided: --foo --pop --lol
      --prune requires a value <days>
    EOS
  end

  it "checks help message when argument(s) present" do
    command = Homebrew::Command
    command.options do
      command.cmd_name "commands"
      command.argument :formulae
      command.argument :formulae1
      command.argument :cat, optional: true
      command.argument :bus, optional: true
      command.desc "Show a list of built-in and external commands."
      command.option "quiet", desc: "list only the names of commands without the header." do
        command.option "include-aliases", desc: "the aliases of internal commands will be included."
      end
      command.option "prune", value: "days", desc: "remove all cache files older than <days>."
      command.option "prune1", value: "days", desc: "remove all cache files older than <days>."
    end
    command.generate_help_and_manpage_output
    expect(command.help_output).to eq <<-EOS.undent
      brew commands [--quiet [--include-aliases]] [--prune=days] [--prune1=days] [cat] [bus] formulae formulae1:
          Show a list of built-in and external commands.

          If --quiet is passed, list only the names of commands without the header.
          With --include-aliases, the aliases of internal commands will be included.

          If --prune=days is specified, remove all cache files older than days.

          If --prune1=days is specified, remove all cache files older than days.
    EOS
      .slice(0..-2)
  end
end
