require "utils/analytics"

describe Utils::Analytics do
  describe "::os_prefix_ci" do
    context "when anonymous_os_prefix_ci is not set" do
      it "returns OS_VERSION and prefix when HOMEBREW_PREFIX is not /usr/local" do
        expect(described_class.os_prefix_ci).to include("#{OS_VERSION}, non-/usr/local")
      end

      it "includes CI when ENV['CI'] is set" do
        CI = ENV["CI"]
        ENV["CI"] = "true"

        expect(described_class.os_prefix_ci).to include("CI")

        ENV["CI"] = CI
      end

      it "does not include prefix when HOMEBREW_PREFIX is usr/local" do
        allow(HOMEBREW_PREFIX).to receive(:to_s).and_return("/usr/local")
        expect(described_class.os_prefix_ci).not_to include("non-/usr/local")
      end
    end

    context "when anonymous_os_prefix_ci is set" do
      let(:anonymous_os_prefix_ci) { "macOS 10.11.6, non-/usr/local, CI" }

      it "returns anonymous_os_prefix_ci" do
        described_class.instance_variable_set(:@anonymous_os_prefix_ci, anonymous_os_prefix_ci)
        expect(described_class.os_prefix_ci).to eq(anonymous_os_prefix_ci)
      end
    end
  end

  describe "::report_event" do
    before(:all) do
      ANALYTICS_DEBUG = ENV["HOMEBREW_ANALYTICS_DEBUG"]
      NO_ANALYTICS_THIS_RUN = ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"]
      NO_ANALYTICS = ENV["HOMEBREW_NO_ANALYTICS"]
    end

    let(:f) { formula { url "foo-1.0" } }
    let(:options) { FormulaInstaller.new(f).display_options(f) }
    let(:action)  { "#{f.full_name} #{options}".strip }

    context "when ENV vars is set" do
      it "returns nil when HOMEBREW_NO_ANALYTICS is true" do
        ENV["HOMEBREW_NO_ANALYTICS"] = "true"

        expect(described_class.report_event("install", action)).to be_nil

        ENV["HOMEBREW_NO_ANALYTICS"] = NO_ANALYTICS
      end

      it "returns nil when HOMEBREW_NO_ANALYTICS_THIS_RUN is true" do
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = "true"

        expect(described_class.report_event("install", action)).to be_nil

        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = NO_ANALYTICS_THIS_RUN
      end

      # [WIP]
      it "returns nil when HOMEBREW_ANALYTICS_DEBUG is true" do
        ENV["HOMEBREW_ANALYTICS_DEBUG"] = "true"
        ENV["HOMEBREW_NO_ANALYTICS"] = nil
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = nil

        shutup do
          described_class.report_event("install", action)
        end

        ENV["HOMEBREW_ANALYTICS_DEBUG"] = ANALYTICS_DEBUG
        ENV["HOMEBREW_NO_ANALYTICS"] = NO_ANALYTICS
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = NO_ANALYTICS_THIS_RUN
      end
    end

    context "when ENV vars are nil" do
      it "returns nil when HOMEBREW_ANALYTICS_DEBUG is not set" do
        ENV["HOMEBREW_NO_ANALYTICS"] = nil
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = nil

        shutup do
          expect(described_class.report_event("install", action)).to be_an_instance_of(Thread)
        end

        ENV["HOMEBREW_NO_ANALYTICS"] = NO_ANALYTICS
        ENV["HOMEBREW_NO_ANALYTICS_THIS_RUN"] = NO_ANALYTICS_THIS_RUN
      end
    end
  end
end
