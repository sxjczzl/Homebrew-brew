# typed: false
# frozen_string_literal: true

require "cmd/update-report"
require "formula_versions"
require "yaml"
require "cmd/shared_examples/args_parse"

describe "brew update-report" do
  it_behaves_like "parseable arguments"

  describe Reporter do
    let(:tap) { CoreTap.new }
    let(:reporter_class) do
      Class.new(described_class) do
        def initialize(tap)
          @tap = tap

          ENV["HOMEBREW_UPDATE_BEFORE#{tap.repo_var}"] = "12345678"
          ENV["HOMEBREW_UPDATE_AFTER#{tap.repo_var}"] = "abcdef00"

          super(tap)
        end
      end
    end
    let(:reporter) { reporter_class.new(tap) }
    let(:hub) { ReporterHub.new }

    def perform_update(fixture_name = "")
      allow(Formulary).to receive(:factory).and_return(double(pkg_version: "1.0"))
      allow(FormulaVersions).to receive(:new).and_return(double(formula_at_revision: "2.0"))

      diff = YAML.load_file("#{TEST_FIXTURE_DIR}/updater_fixture.yaml")[fixture_name]
      allow(reporter).to receive(:diff).and_return(diff || "")

      hub.add(reporter) if reporter.updated?
    end

    specify "without revision variable" do
      ENV.delete_if { |k, _v| k.start_with? "HOMEBREW_UPDATE" }

      expect {
        described_class.new(tap)
      }.to raise_error(Reporter::ReporterRevisionUnsetError)
    end

    specify "without any changes" do
      perform_update
      expect(hub).to be_empty
    end

    specify "without Package changes" do
      perform_update("update_git_diff_output_without_packages_changes")

      expect(hub.select_package(:modified, :formulae)).to be_empty
      expect(hub.select_package(:added, :formulae)).to be_empty
      expect(hub.select_package(:deleted, :formulae)).to be_empty
      expect(hub.select_package(:modified, :casks)).to be_empty
      expect(hub.select_package(:added, :casks)).to be_empty
      expect(hub.select_package(:deleted, :casks)).to be_empty
    end

    specify "with Package changes" do
      perform_update("update_git_diff_output_with_packages_changes")

      expect(hub.select_package(:modified, :formulae)).to eq(%w[xar yajl])
      expect(hub.select_package(:added, :formulae)).to eq(%w[antiword bash-completion ddrescue dict lua])
      expect(hub.select_package(:modified, :casks)).to eq(%w[firefox slack])
      expect(hub.select_package(:added, :casks)).to eq(%w[iterm2 docker])
    end

    specify "with removed Packages" do
      perform_update("update_git_diff_output_with_removed_packages")

      expect(hub.select_package(:deleted, :formulae)).to eq(%w[libgsasl])
      expect(hub.select_package(:deleted, :casks)).to eq(%w[ngrok])
    end

    specify "with changed file type" do
      perform_update("update_git_diff_output_with_changed_filetype")

      expect(hub.select_package(:modified, :formulae)).to eq(%w[elixir])
      expect(hub.select_package(:added, :formulae)).to eq(%w[libbson])
      expect(hub.select_package(:deleted, :formulae)).to eq(%w[libgsasl])
      expect(hub.select_package(:modified, :casks)).to eq(%w[xquartz])
      expect(hub.select_package(:added, :casks)).to eq(%w[macfuse])
      expect(hub.select_package(:deleted, :casks)).to eq(%w[discord])
    end

    specify "with renamed Formula" do
      allow(tap).to receive(:formula_renames).and_return("cv" => "progress")
      perform_update("update_git_diff_output_with_formula_rename")

      expect(hub.select_package(:added, :formulae)).to be_empty
      expect(hub.select_package(:deleted, :formulae)).to be_empty
      expect(hub.select_package(:renamed, :formulae)).to eq([["cv", "progress"]])
      expect(hub.select_package(:added, :casks)).to be_empty
      expect(hub.select_package(:deleted, :casks)).to be_empty
      expect(hub.select_package(:renamed, :casks)).to be_empty
    end

    context "when updating a Tap other than the core Tap" do
      let(:tap) { Tap.new("foo", "bar") }

      before do
        (tap.path/"Formula").mkpath
      end

      after do
        tap.path.parent.rmtree
      end

      specify "with restructured Tap" do
        perform_update("update_git_diff_output_with_restructured_tap")

        expect(hub.select_package(:added, :formulae)).to be_empty
        expect(hub.select_package(:deleted, :formulae)).to be_empty
        expect(hub.select_package(:renamed, :formulae)).to be_empty
        expect(hub.select_package(:added, :casks)).to be_empty
        expect(hub.select_package(:deleted, :casks)).to be_empty
        expect(hub.select_package(:renamed, :casks)).to be_empty
      end

      specify "with renamed Formula and restructured Tap" do
        allow(tap).to receive(:formula_renames).and_return("xchat" => "xchat2")
        perform_update("update_git_diff_output_with_formula_rename_and_restructuring")

        expect(hub.select_package(:added, :formulae)).to be_empty
        expect(hub.select_package(:deleted, :formulae)).to be_empty
        expect(hub.select_package(:renamed, :formulae)).to eq([%w[foo/bar/xchat foo/bar/xchat2]])
        expect(hub.select_package(:added, :casks)).to be_empty
        expect(hub.select_package(:deleted, :casks)).to be_empty
        expect(hub.select_package(:renamed, :casks)).to be_empty
      end

      specify "with simulated 'homebrew/php' restructuring" do
        perform_update("update_git_diff_simulate_homebrew_php_restructuring")

        expect(hub.select_package(:added, :formulae)).to be_empty
        expect(hub.select_package(:deleted, :formulae)).to be_empty
        expect(hub.select_package(:renamed, :formulae)).to be_empty
        expect(hub.select_package(:added, :casks)).to be_empty
        expect(hub.select_package(:deleted, :casks)).to be_empty
        expect(hub.select_package(:renamed, :casks)).to be_empty
      end

      specify "with Package changes" do
        perform_update("update_git_diff_output_with_tap_packages_changes")

        expect(hub.select_package(:added, :formulae)).to eq(%w[foo/bar/lua])
        expect(hub.select_package(:modified, :formulae)).to eq(%w[foo/bar/git])
        expect(hub.select_package(:deleted, :formulae)).to be_empty
        expect(hub.select_package(:added, :casks)).to eq(%w[foo/bar/zoom])
        expect(hub.select_package(:modified, :casks)).to eq(%w[foo/bar/vlc])
        expect(hub.select_package(:deleted, :casks)).to be_empty
      end
    end
  end
end
