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
    let(:formula_name) { "testball" }
    let(:cask_name) { "with-conflicts-with-formula" }
    let(:error_msg) { "Cask '#{cask_name}' conflicts with formula '#{formula_name}'." }

    let(:conflicting_formula) {
      setup_test_formula formula_name
      Formula[formula_name]
    }

    let(:cask) {
      Cask::CaskLoader.load(cask_path(cask_name))
    }

    it "installs a Formula and a conflicting Cask" do
      FormulaInstaller.new(conflicting_formula).install

      conflicting_formula.opt_or_installed_prefix_keg.link

      expect(conflicting_formula).to be_latest_version_installed
      expect(conflicting_formula).to be_optlinked

      expect {
        Cask::Installer.new(cask).install
      }.to raise_error(Cask::CaskFormulaConflictError, error_msg)

      expect(cask).not_to be_installed
    end
  end
end
