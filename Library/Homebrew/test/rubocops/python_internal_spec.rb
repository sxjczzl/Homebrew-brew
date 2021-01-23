# typed: false
# frozen_string_literal: true

require "rubocops/python_internal"

describe RuboCop::Cop::FormulaAudit::DependsOnPythonInternalCop do
  subject(:cop) { described_class.new }

  let(:path) { Tap::TAP_DIRECTORY/"homebrew/homebrew-core" }

  before do
    path.mkpath
    (path/"style_exceptions").mkpath
  end

  def setup_style_exceptions
    (path/"style_exceptions/depends_on_python_internal_allowlist.json").write <<~JSON
      [ "libxcb" ]
    JSON
  end

  it "fails for formulae not in the python_internal_allowlist" do
    setup_style_exceptions

    expect_offense(<<~RUBY, "#{path}/Formula/baz.rb")
      class Baz < Formula
        url "https://brew.sh/baz-1.0.tgz"
        homepage "https://brew.sh"

        depends_on "python-internal"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This formula is not allowed to depend on python-internal.
      end
    RUBY
  end

  it "succeeds for formulae in the python_internal_allowlist" do
    setup_style_exceptions

    expect_no_offenses(<<~RUBY, "#{path}/Formula/libxcb.rb")
      class Libxcb < Formula
        url "https://brew.sh/apr-1.0.tgz"
        homepage "https://brew.sh"

        depends_on "python-internal" => :build
      end
    RUBY
  end

  it "fails if python-internal is not a build dependcy" do
    setup_style_exceptions

    expect_offense(<<~RUBY, "#{path}/Formula/libxcb.rb")
      class Libxcb < Formula
        url "https://brew.sh/baz-1.0.tgz"
        homepage "https://brew.sh"

        depends_on "python-internal" => :test
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The python-internal dependency can only be a :build dependency.
      end
    RUBY
  end

  it "fails if python-internal is not a build dependcy" do
    setup_style_exceptions

    expect_offense(<<~RUBY, "#{path}/Formula/libxcb.rb")
      class Libxcb < Formula
        url "https://brew.sh/baz-1.0.tgz"
        homepage "https://brew.sh"

        depends_on "python-internal" => [:test, :build]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ The python-internal dependency can only be a :build dependency.
      end
    RUBY
  end
end
