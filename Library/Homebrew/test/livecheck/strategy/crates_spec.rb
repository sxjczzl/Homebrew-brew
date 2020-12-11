# typed: false
# frozen_string_literal: true

require "livecheck/strategy/crates"

describe Homebrew::Livecheck::Strategy::Crates do
  subject(:crates) { described_class }

  let(:crates_api_url) { "https://crates.io/api/v1/crates/brew-1.2.3/download" }
  let(:crates_static_url) { "https://static.crates.io/crates/brew/brew-1.2.3.crate" }
  let(:non_crates_url) { "https://brew.sh/test" }

  describe "::match?" do
    it "returns true if the argument provided is a crates URL" do
      expect(crates.match?(crates_api_url)).to be true
      expect(crates.match?(crates_static_url)).to be true
    end

    it "returns false if the argument provided is not a crates URL" do
      expect(crates.match?(non_crates_url)).to be false
    end
  end
end
