require "command/parse_arguments"
require "command/define_command"

# TODO: Move the test cases of each class/sub-class into separate files

describe Homebrew::Command do
  before(:each) { stub_const("ARGV", []) }
  before(:each) do
    described_class.define "test-cmd1" do
      desc "this is a test command description"

      option "--option1" do
        desc <<-EOS.undent
          If #{@option} is passed, execute function option1()
        EOS
      end

      option "--option2" do
        desc <<-EOS.undent
          If #{@option} is passed, execute function option2()
        EOS
      end

      run do
        puts "the command `test-cmd1` was just executed"
        puts "this is the second line"
      end
    end
  end

  it "runs a test command" do
    expect { described_class.run("test-cmd1") }
      .to output(/the command `test-cmd1` was just executed/).to_stdout
  end

  it "checks for no error message if no invalid option provided" do
    stub_const("ARGV", ["--option1"])
    error_msg = described_class::ParseArguments.new("test-cmd1").error_msg
    expect(error_msg).to eq(nil)
  end

  it "checks for an error message if invalid option provided" do
    stub_const("ARGV", ["--option1", "--option3"])
    error_msg = described_class::ParseArguments.new("test-cmd1").error_msg
    expect(error_msg).to eq("Invalid option(s) provided: --option3")
  end

  it "checks subsitute functions for ARGV.include?() are generated" do
    stub_const("ARGV", ["--option1"])
    described_class::ParseArguments.new("test-cmd1").generate_command_line_parsing_methods
    expect(Homebrew.option1?).to eq(true)
  end
end
