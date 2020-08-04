# frozen_string_literal: true

require "formula_keeper"
require "cmd/shared_examples/args_parse"

describe "brew unkeep" do
  describe "Homebrew.unkeep_args" do
    it_behaves_like "parseable arguments"
  end

  describe "brew unkeep", :integration_test do
    it "unkeeps a Formula's version" do
      install_test_formula "testball"
      FormulaKeeper.keep(Formula["testball"])

      expect { brew "unkeep", "testball" }.to be_a_success
    end
  end
end
