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

describe "conflicts_with", :formula do
  describe "conflicts_with formula" do
    let(:cmake_formula) {
      Formula["cmake"]
    }

    let(:cmake_cask) {
      Cask::CaskLoader.load(cask_path("cmake"))
    }

    it "installs a Formula and a conflicting Cask" do
      FormulaInstaller.new(cmake_formula).install

      expect(cmake_formula).to be_latest_version_installed

      expect {
        Cask::Installer.new(cmake_cask).install
      }.to raise_error(Cask::CaskConflictError, "Cask 'cmake' conflicts with 'cmake'.")

      expect(cmake_cask).not_to be_installed
    end
  end
end
