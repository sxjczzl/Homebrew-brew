require "diagnostic"

describe Homebrew::Diagnostic::Checks do
  specify "#check_dll_minimum_version" do
    allow(OS::Cygwin::DLL).to receive(:below_minimum_version?).and_return(true)

    expect(subject.check_dll_minimum_version)
      .to match(/Your Cygwin DLL .+ is too old/)
  end
end
