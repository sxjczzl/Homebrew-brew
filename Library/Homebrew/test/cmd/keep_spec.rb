# frozen_string_literal: true

require "cmd/shared_examples/args_parse"

describe "brew keep" do
  describe "Homebrew.keep_args" do
    it_behaves_like "parseable arguments"
  end

  describe "brew keep", :integration_test do
    it "keeps a Formula" do
      install_test_formula "testball"

      expect { brew "keep", "testball" }.to be_a_success
    end
  end
end
