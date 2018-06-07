describe "brew --env", :integration_test do
  it "prints the Homebrew build environment variables" do
    expect { brew "--env" }
    not_to_output.to_stderr
      .and be_a_success
  end

  describe "--shell=bash" do
    it "prints the Homebrew build environment variables in Bash syntax" do
      expect { brew "--env", "--shell=bash" }
      not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "--shell=fish" do
    it "prints the Homebrew build environment variables in Fish syntax" do
      expect { brew "--env", "--shell=fish" }
      not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "--shell=tcsh" do
    it "prints the Homebrew build environment variables in Tcsh syntax" do
      expect { brew "--env", "--shell=tcsh" }
      not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "--plain" do
    it "prints the Homebrew build environment variables without quotes" do
      expect { brew "--env", "--plain" }
      not_to_output.to_stderr
        .and be_a_success
    end
  end
end
