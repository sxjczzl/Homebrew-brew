require "command_options"

describe Homebrew::CommandOptions do
  it "initializes correctly" do
    command_options = Homebrew::CommandOptions.new("test command")
    expect(command_options.command_name).to eq("test command")
    expect(command_options.valid_options).to eq({})
  end

  it "sets valid_options correctly" do
    command_options = Homebrew::CommandOptions.new("test command")
    command_options.option("--bar")
    command_options.option("--foo", "do foo")
    command_options.option("--quiet", "be quiet")
    expect(command_options.valid_options).to eq("--foo"=>"do foo",
      "--quiet"=>"be quiet",
      "--bar"=>"No description for this option is available")
  end

  it "sets error message correctly if only one invalid option provided" do
    command_options = Homebrew::CommandOptions.new("test command")
    command_options.option("--bar")
    argv_options = ["--foo"]
    error_message = command_options.get_error_message(argv_options)
    expect(error_message).to \
      include("<test command> has only 1 valid option: --bar")
  end

  it "sets error message correctly if more than one invalid options provided" do
    command_options = Homebrew::CommandOptions.new("test command")
    command_options.option("--bar")
    command_options.option("--foo", "do foo")
    command_options.option("--quiet", "be quiet")
    argv_options = ["--bar1", "--bar2", "--bar1", "--bar", "--foo"]
    expect(command_options.get_error_message(argv_options)).to eq <<-EOS.undent
      2 invalid options provided: --bar1 --bar2
      <test command> has only 3 valid options: --bar --foo --quiet

          --bar:  No description for this option is available
          --foo:  do foo
          --quiet:  be quiet

    EOS
  end

  it "produces no error message if only valid options provided" do
    command_options = Homebrew::CommandOptions.new("test command")
    command_options.option("--bar")
    command_options.option("--foo", "do foo")
    command_options.option("--quiet", "be quiet")
    expect(command_options.get_error_message(["--quiet", "--bar"])).to eq(nil)
  end
end
