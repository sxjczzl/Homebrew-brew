describe "brew deps", :integration_test do
  before do
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<~RUBY
      url "https://example.com/baz-1.0"
      depends_on "bar"
    RUBY
  end

  it "outputs no dependencies for a Formula that has no dependencies" do
    expect { brew "deps", "foo" }
      .to be_a_success
      .and not_to_output.to_stdout
      .and not_to_output.to_stderr
  end

  it "outputs all of a Formula's dependencies and their dependencies on separate lines" do
    expect { brew "deps", "baz" }
      .to be_a_success
      .and output("bar\nfoo\n").to_stdout
      .and not_to_output.to_stderr
  end

  it "outputs dependencies for all formulae with the --all flag" do
    expect { brew "deps", "--all" }
      .to be_a_success
      .and output(/bar: foo\nbaz: bar/).to_stdout
      .and not_to_output.to_stderr
  end

  it "outputs a tree of dependencies with the --tree flag" do
    expect { brew "deps", "foo", "--tree" }
      .to be_a_success
      .and output(/foo\s*/).to_stdout
      .and not_to_output.to_stderr

    expect { brew "deps", "baz", "--tree" }
      .to be_a_success
      .and output("baz\n└── bar\n    └── foo\n\n").to_stdout
      .and not_to_output.to_stderr
  end

  it "outputs dependencies for a given list of formulae with the --for-each flag" do
    expect { brew "deps", "foo", "bar", "--for-each" }
      .to be_a_success
      .and output(/bar: foo/).to_stdout
      .and not_to_output.to_stderr
  end

  it "gives an error if run with incorrrect arguments" do
    expect { brew "deps" }
      .to output(/Invalid usage/).to_stderr
      .and not_to_output.to_stdout

    expect { brew "deps", "--tree" }
      .to output(/Invalid usage/).to_stderr
      .and not_to_output.to_stdout
  end
end
