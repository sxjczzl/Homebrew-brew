# frozen_string_literal: true

require "formula_keeper"

describe FormulaKeeper do
  let(:name) { "double" }
  let(:formula) { instance_double(Formula, name: name, rack: HOMEBREW_CELLAR/name) }

  before do
    formula.rack.mkpath

    allow(formula).to receive(:installed_prefixes) do
      formula.rack.directory? ? formula.rack.subdirs.sort : []
    end

    allow(formula).to receive(:installed_kegs) do
      formula.installed_prefixes.map { |prefix| Keg.new(prefix) }
    end
  end

  it "is not keepable by default" do
    expect(described_class.keepable?(formula)).to eq(false)
  end

  it "is keepable if the Keg exists" do
    (formula.rack/"0.1").mkpath
    expect(described_class.keepable?(formula)).to eq(true)
  end

  specify "#keep and #unkeep" do
    (formula.rack/"0.1").mkpath

    described_class.keep(formula)
    expect(described_class.keeping?(formula)).to be(true)
    expect(HOMEBREW_KEEP_FORMULAE/name).to be_a_file
    expect(HOMEBREW_KEEP_FORMULAE.children.count).to eq(1)

    described_class.unkeep(formula)
    expect(described_class.keeping?(formula)).to be(false)
    expect(HOMEBREW_KEEP_FORMULAE).not_to be_a_directory
  end

  describe "brew uninstall", :integration_test do
    it "does not uninstall a kept Formula without `--force`" do
      install_test_formula "testball"

      expect { brew "keep", "testball" }.to be_a_success

      expect { brew "uninstall", "testball" }
        .to output(/Error/).to_stderr
        .and not_to_output.to_stdout
        .and be_a_success
    end

    it "uninstalls a kept Formula with `--force`" do
      install_test_formula "testball"

      expect { brew "keep", "testball" }.to be_a_success

      expect { brew "uninstall", "--force", "testball" }
        .to output(/Uninstalling testball/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end
