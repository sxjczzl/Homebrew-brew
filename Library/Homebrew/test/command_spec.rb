require "cmd/commands"
require "command/documentation"
require "command/parse_arguments"
require "command/define_command"

# TODO: Move the test cases of each class/sub-class into seperate files

describe Homebrew::Command do
  before(:each) { stub_const("ARGV", []) }
  before(:each) do
    described_class.define_command "test-cmd1" do
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

  it "runs a test command using the `define_command` DSL method" do
    expect { described_class.run_command("test-cmd1") }
      .to output(/the command `test-cmd1` was just executed/).to_stdout
  end

  it "checks for correct error message on a test command" do
    stub_const("ARGV", ["--option1"])
    error_msg = described_class::ParseArguments.new("test-cmd1").error_msg
    expect(error_msg).to eq(nil)

    stub_const("ARGV", ["--option1", "--option3"])
    error_msg = described_class::ParseArguments.new("test-cmd1").error_msg
    expect(error_msg).to eq("Invalid option(s) provided: --option3")
  end
end
