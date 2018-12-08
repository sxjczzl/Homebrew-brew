describe "brew donate", :integration_test do
  it "execs Kernel#exec to open the donate URL" do
    expect(Kernel).to receive(:exec).with('open https://github.com/Homebrew/brew#donations').and_return(true)
    expect { brew "donate"}.to be_a_success
  end
end
