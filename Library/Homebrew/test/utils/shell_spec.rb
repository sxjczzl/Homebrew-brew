require "utils/shell"

describe Utils::Shell do
  describe "::profile" do
    it "returns ~/.bash_profile by default" do
      ENV["SHELL"] = "/bin/another_shell"
      expect(subject.profile).to eq("~/.bash_profile")
    end

    it "returns ~/.bash_profile for sh" do
      ENV["SHELL"] = "/bin/sh"
      expect(subject.profile).to eq("~/.bash_profile")
    end

    it "returns ~/.bash_profile for Bash" do
      ENV["SHELL"] = "/bin/bash"
      expect(subject.profile).to eq("~/.bash_profile")
    end

    it "returns ~/.zshrc for Zsh" do
      ENV["SHELL"] = "/bin/zsh"
      expect(subject.profile).to eq("~/.zshrc")
    end

    it "returns ~/.kshrc for Ksh" do
      ENV["SHELL"] = "/bin/ksh"
      expect(subject.profile).to eq("~/.kshrc")
    end
  end

  describe "::from_path" do
    it "supports a raw command name" do
      expect(subject.from_path("bash")).to eq(:bash)
    end

    it "supports full paths" do
      expect(subject.from_path("/bin/bash")).to eq(:bash)
    end

    it "supports versions" do
      expect(subject.from_path("zsh-5.2")).to eq(:zsh)
    end

    it "strips newlines" do
      expect(subject.from_path("zsh-5.2\n")).to eq(:zsh)
    end

    it "returns nil when input is invalid" do
      expect(subject.from_path("")).to be nil
      expect(subject.from_path("@@@@@@")).to be nil
      expect(subject.from_path("invalid_shell-4.2")).to be nil
    end
  end

  specify "::sh_quote" do
    expect(subject.send(:sh_quote, "")).to eq("''")
    expect(subject.send(:sh_quote, "\\")).to eq("\\\\")
    expect(subject.send(:sh_quote, "\n")).to eq("'\n'")
    expect(subject.send(:sh_quote, "$")).to eq("\\$")
    expect(subject.send(:sh_quote, "word")).to eq("word")
  end

  specify "::csh_quote" do
    expect(subject.send(:csh_quote, "")).to eq("''")
    expect(subject.send(:csh_quote, "\\")).to eq("\\\\")
    # note this test is different than for sh
    expect(subject.send(:csh_quote, "\n")).to eq("'\\\n'")
    expect(subject.send(:csh_quote, "$")).to eq("\\$")
    expect(subject.send(:csh_quote, "word")).to eq("word")
  end

  describe "::prepend_path_in_profile" do
    let(:path) { "/my/path" }

    it "supports Tcsh" do
      ENV["SHELL"] = "/bin/tcsh"
      expect(subject.prepend_path_in_profile(path))
        .to eq("echo 'setenv PATH #{path}:$PATH' >> #{shell_profile}")
    end

    it "supports Bash" do
      ENV["SHELL"] = "/bin/bash"
      expect(subject.prepend_path_in_profile(path))
        .to eq("echo 'export PATH=\"#{path}:$PATH\"' >> #{shell_profile}")
    end

    it "supports Fish" do
      ENV["SHELL"] = "/usr/local/bin/fish"
      ENV["fish_user_paths"] = "/some/path"
      expect(subject.prepend_path_in_profile(path))
        .to eq("echo 'set -g fish_user_paths \"#{path}\" $fish_user_paths' >> #{shell_profile}")
    end
  end
end

describe "String#for_shell" do
  using Utils::Shell

  subject { "prefix $(whoami) suffix" }

  it "returns (...) for fish" do
    ENV["SHELL"] = "/usr/local/bin/fish"
    expect(subject.for_shell).to eq("prefix (whoami) suffix")
  end
  %w[bash csh ksh sh tcsh zsh].each do |shell|
    it "returns $(...) for #{shell}" do
      ENV["SHELL"] = "/bin/#{shell}"
      expect(subject.for_shell).to eq("prefix $(whoami) suffix")
    end
  end

  context "fish-shell" do
    before do
      ENV["SHELL"] = "/usr/local/bin/fish"
    end

    it "unquotes enclosed subshells" do
      expect('ls "$(brew --repo)"'.for_shell).to eq("ls (brew --repo)")
    end

    it "chains with heredoc" do
      expect(
        <<~EOS.for_shell
          prefix $(whoami) suffix
        EOS
      ).to eq("prefix (whoami) suffix\n")
    end

    it "converts existing example commands" do
      expect(
        <<~EOS.for_shell
          Homebrew/homebrew-core is not on the master branch

          Check out the master branch by running:
            git -C "$(brew --repo homebrew/core)" checkout master
        EOS
      ).to eq(
        <<~EOS
          Homebrew/homebrew-core is not on the master branch

          Check out the master branch by running:
            git -C (brew --repo homebrew/core) checkout master
        EOS
      )
    end

    it "converts existing example commands with string substitution" do
      name = "Homebrew/brew"
      git_cd = "$(brew --repo)"

      expect(
        <<~EOS.for_shell
          #{name} is a shallow clone so only partial output will be shown.
          To get a full clone run:
            git -C "#{git_cd}" fetch --unshallow
        EOS
      ).to eq(
        <<~EOS
          Homebrew/brew is a shallow clone so only partial output will be shown.
          To get a full clone run:
            git -C (brew --repo) fetch --unshallow
        EOS
      )
    end
  end
end
