# typed: false
# frozen_string_literal: true

require "cmd/shared_examples/args_parse"

describe "brew uses" do
  it_behaves_like "parseable arguments"

  it "prints the Formulae a given Formula is used by", :integration_test do
    setup_test_formula "foo"
    setup_test_formula "bar"
    setup_test_formula "baz", <<~RUBY
      url "https://brew.sh/baz-1.0"
      depends_on "bar"
    RUBY

    expect { brew "uses", "--recursive", "foo" }
      .to output("bar\nbaz\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "skips dependents of test dependents", :integration_test do
    setup_test_formula "foo"
    setup_test_formula "baz", <<~RUBY
      url "https://brew.sh/baz-1.0"
      depends_on "foo" => :test
    RUBY
    setup_test_formula "qux", <<~RUBY
      url "https://brew.sh/qux-1.0"
      depends_on "baz"
    RUBY

    expect { brew "uses", "--recursive", "--include-test", "foo" }
      .to output("baz\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints build dependents when requested", :integration_test do
    setup_test_formula "foo"
    setup_test_formula "baz", <<~RUBY
      url "https://brew.sh/baz-1.0"
      depends_on "foo" => :build
    RUBY
    setup_test_formula "qux", <<~RUBY
      url "https://brew.sh/qux-1.0"
      depends_on "baz"
    RUBY

    expect { brew "uses", "--recursive", "--include-build", "foo" }
      .to output("baz\nqux\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "skips dependents of build dependents when requested", :integration_test do
    setup_test_formula "foo"
    setup_test_formula "baz", <<~RUBY
      url "https://brew.sh/baz-1.0"
      depends_on "foo" => :build
    RUBY
    setup_test_formula "qux", <<~RUBY
      url "https://brew.sh/qux-1.0"
      depends_on "baz"
    RUBY

    expect { brew "uses", "--recursive", "--include-build", "--skip-recursive-build-dependents", "foo" }
      .to output("baz\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
