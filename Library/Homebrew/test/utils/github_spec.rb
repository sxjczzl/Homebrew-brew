require "utils/github"

describe GitHub do
  describe "::search_code", :needs_network do
    it "searches code" do
      results = subject.search_code("repo:Homebrew/brew", "path:/", "filename:readme", "language:markdown")

      expect(results.count).to eq(1)
      expect(results.first["name"]).to eq("README.md")
      expect(results.first["path"]).to eq("README.md")
    end
  end

  describe "::issues_for_formula" do
    let(:tap) { Tap.new "user", "my-repo" }
    before(:each) { allow(tap).to receive(:remote).and_return(remote) }

    context "with custom_remote tap" do
      let(:remote) { "https://github.com/user/my-custom-repo" }

      it "returns []" do
        expect(described_class.issues_for_formula("some-formula", tap: tap)).to be_empty
      end
    end

    context "with GitHub Enterprise tap" do
      let(:remote) { "https://github.my-org.com/user/homebrew-repo" }

      it "returns []" do
        expect(described_class.issues_for_formula("some-formula", tap: tap)).to be_empty
      end
    end
  end
end
