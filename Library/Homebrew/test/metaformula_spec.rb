require "metaformula"

describe MetaFormula do
  context "when calling from homebrew" do
    def metaformula(name = "metaformula_name", path: Formulary.core_path(name), &block)
      Class.new(MetaFormula, &block).new(name, path, :stable)
    end

    subject(:f) {
      metaformula do
        version "1.0.0"
      end
    }

    describe "::new" do
      let(:klass) { Class.new(described_class) do version "0.1.0" end }
      let(:name) { "metafoo" }
      let(:path) { Formulary.core_path(name) }

      it "only accepts :stable spec" do
        expect(f.active_spec_sym).to eq(:stable)
        expect { klass.new(name, path, :head)  }.to raise_error(FormulaSpecificationError)
        expect { klass.new(name, path, :devel) }.to raise_error(FormulaSpecificationError)
      end
    end

    describe "#validate_attributes!" do
      let(:f_noversion) do
        metaformula
      end

      it "does not require a url" do
        expect { f.validate_attributes! }.not_to raise_error
      end

      it "requires a version" do
        expect { f_noversion.validate_attributes! }.to raise_error(FormulaValidationError)
      end
    end

    describe "#bottle_disabled?" do
      it "always return true" do
        expect(f.bottle_disabled?).to be true
      end
    end

    specify "only :stable class specs is allow" do
      expect(f.class.specs).to eq [f.class.stable]
      expect(f.class.stable).to be_kind_of(SoftwareSpec)
      expect { f.class.head  }.to raise_error
      expect { f.class.devel }.to raise_error
    end

    disabled_dsls = [:bottle, :patch]

    disabled_dsls.each do |dsl|
      specify "#{dsl} is disabled" do
        expect { f.class.send(dsl) }.to raise_error
      end
    end
  end

  context "when calling from CLI", :integration_test do
    def setup_test_metaformula(name, content = nil)
      Formulary.core_path(name).tap do |formula_path|
        formula_path.write <<~EOS
          class #{Formulary.class_s(name)} < MetaFormula
            #{content}
          end
        EOS
      end
    end

    def get_test_cask(name, content = nil)
      <<~EOS
        cask '#{name}' do
          sha256 '67cdb8a02803ef37fdbf7e0be205863172e41a561ca446cd84f0d7ab35a99d94'
          url "file://#{TEST_FIXTURE_DIR}/cask/caffeine.zip"
          #{content}
        end
      EOS
    end

    def setup_test_cask(name, content = nil)
      content = get_test_cask(name, content)
      Hbc::CaskLoader.default_path(name).tap do |cask_path|
        cask_path.write content
      end
    end

    def mock_installed_formula(name, version)
      (HOMEBREW_CELLAR/name/version/"xxx").mkpath
    end

    def mock_installed_cask(name, version)
      content = get_test_cask(name, "version '#{version}'")
      mock_timestamp = "xxx"
      (Hbc::Caskroom.path/name/".metadata"/version/mock_timestamp/"Casks/#{name}.rb").write content
      (Hbc::Caskroom.path/name/version/"xxx").mkpath
    end

    before do
      Tap.default_cask_tap.path.mkpath
      Hbc::Caskroom.path.mkpath

      setup_test_metaformula "foo", <<~EOS
        version "1.0.0"
        depends_on "bar"
        depends_on :cask => "baz"
      EOS

      setup_test_metaformula "bar", <<~EOS
        version "1.0.0"
      EOS

      setup_test_cask "baz", <<~EOS
        version "1.0.0"
      EOS
    end

    define_method :foo_meta do Formula["foo"] end
    define_method :bar_form do Formula["bar"] end
    define_method :baz_cask do Hbc::CaskLoader.load("baz") end

    describe "brew install" do
      it "requires --allow-metaformula" do
        expect(bar_form).not_to be_installed

        expect { brew "install", "bar" }
          .to output(/--allow-metaformula/).to_stderr
          .and not_to_output.to_stdout
          .and be_a_failure

        expect { brew "install", "bar", "--allow-metaformula" }
          .to output(%r{#{HOMEBREW_CELLAR}/bar/1\.0}).to_stdout
          .and not_to_output.to_stderr
          .and be_a_success

        expect(bar_form).to be_installed
      end

      it "installs casks & formulae" do
        expect(bar_form).not_to be_installed
        expect(baz_cask).not_to be_installed

        expect { brew "install", "foo", "--allow-metaformula" }.to be_a_success

        expect(bar_form).to be_installed
        expect(baz_cask).to be_installed
      end
    end

    describe "brew upgrade" do
      it "upgrades casks & formulae" do
        mock_installed_formula("foo", "0.0.1")
        mock_installed_formula("bar", "0.0.1")
        mock_installed_cask("baz", "0.0.1")

        [foo_meta, bar_form, baz_cask].each { |f| expect(f).to be_outdated }

        expect { brew "upgrade", "foo", "--allow-metaformula" }.to be_a_success

        [foo_meta, bar_form, baz_cask].each { |f| expect(f).not_to be_outdated }
      end
    end

    describe "brew list" do
      before do
        mock_installed_formula("foo", "1.0.0")
        mock_installed_formula("bar", "1.0.0")
        mock_installed_cask("baz", "1.0.0")

        setup_test_metaformula "qux", <<~EOS
          version "1.0.0"
          depends_on "foo"
          depends_on :cask => "baz"
        EOS
        mock_installed_formula("qux", "1.0.0")
      end

      it "prints dependencies of metaformulae" do
        expect { brew "list", "--meta", "foo" }
          .to output("bar\nbaz\n").to_stdout
      end

      it "only one level of dependencies will be printed" do
        expect { brew "list", "--meta", "qux" }
          .to not_to_output(/bar/).to_stdout
      end

      it "use --casks to only list cask dependencies" do
        expect { brew "list", "--meta", "foo", "--casks" }
          .to output("baz\n").to_stdout
      end

      it "use --brews to only list formula dependencies" do
        expect { brew "list", "--meta", "foo", "--brews" }
          .to output("bar\n").to_stdout
      end
    end
  end
end
