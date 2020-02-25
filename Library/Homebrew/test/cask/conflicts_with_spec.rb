# frozen_string_literal: true

describe "conflicts_with", :cask do
  describe "conflicts_with cask" do
    let(:local_caffeine) {
      Cask::CaskLoader.load(cask_path("local-caffeine"))
    }

    let(:with_conflicts_with) {
      Cask::CaskLoader.load(cask_path("with-conflicts-with"))
    }

    it "installs the dependency of a Cask and the Cask itself" do
      Cask::Installer.new(local_caffeine).install

      expect(local_caffeine).to be_installed

      expect {
        Cask::Installer.new(with_conflicts_with).install
      }.to raise_error(Cask::CaskConflictError, "Cask 'with-conflicts-with' conflicts with 'local-caffeine'.")

      expect(with_conflicts_with).not_to be_installed
    end
  end
end

describe "conflicts_with", :integration_test do
  describe "conflicts_with formula" do
    let(:testball_formula) {
      setup_test_formula "testball"
      Formula["testball"]
    }

    let(:with_conflicts_with_formula_cask) {
      Cask::CaskLoader.load(cask_path("with-conflicts-with-formula"))
    }

    it "installs a Formula and a conflicting Cask" do
      FormulaInstaller.new(testball_formula).install

      expect(testball_formula).to be_latest_version_installed

      expect {
        Cask::Installer.new(with_conflicts_with_formula_cask).install
      }.to raise_error(Cask::CaskFormulaConflictError, "Cask 'with-conflicts-with-formula' conflicts with formula 'testball'.")

      expect(with_conflicts_with_formula_cask).not_to be_installed
    end
  end
end
