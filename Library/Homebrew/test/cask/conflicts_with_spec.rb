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

  describe "conflicts_with formula", :integration_test do
    FORMULA = "testball"
    CASK = "with-conflicts-with-formula"

    let(:test_formula) {
      setup_test_formula FORMULA
      Formula[FORMULA]
    }

    let(:test_cask) {
      Cask::CaskLoader.load(cask_path(CASK))
    }

    it "installs a Formula and a conflicting Cask" do
      FormulaInstaller.new(test_formula).install

      expect(test_formula).to be_latest_version_installed

      expect {
        Cask::Installer.new(test_cask).install
      }.to raise_error(Cask::CaskFormulaConflictError, "Cask '#{CASK}' conflicts with formula '#{FORMULA}'.")

      expect(test_cask).not_to be_installed
    end
  end
end
