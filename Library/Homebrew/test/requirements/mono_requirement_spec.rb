require "requirements/mono_requirement"
require "fileutils"

describe MonoRequirement do
  subject(:requirement) { described_class.new([]) }

  describe "::mono_installed?", :needs_macos do
    alias_matcher :have_mono_installed, :be_mono_installed

    it "returns false if mono command does not exist" do
      allow(File).to receive(:exist?).and_return(false)
      expect(described_class).not_to have_mono_installed
    end
  end

  describe "#modify_build_environment", :needs_macos do
    it "adds the mono directories to PKG_CONFIG_PATH" do
      allow(ENV).to receive(:append_path)
      requirement.modify_build_environment
      expect(ENV).to have_received(:append_path).with("PKG_CONFIG_PATH", any_args)
    end

    it "adds the mono directories to HOMEBREW_LIBRARY_PATHS" do
      allow(ENV).to receive(:append_path)
      requirement.modify_build_environment
      expect(ENV).to have_received(:append_path).with("HOMEBREW_LIBRARY_PATHS", any_args)
    end

    it "adds the mono directories to HOMEBREW_INCLUDE_PATHS" do
      allow(ENV).to receive(:append_path)
      requirement.modify_build_environment
      expect(ENV).to have_received(:append_path).with("HOMEBREW_INCLUDE_PATHS", any_args)
    end
  end

  describe "#message" do
    it "prompts for installation of 'mono' on Linux", :needs_linux do
      expect(requirement.message).to match("mono-project.com/download")
    end

    it "prompts for installation of 'mono' on macOS", :needs_macos do
      expect(requirement.message).to match("mono-project.com/download")
    end
  end

  describe "#display_s" do
    context "without specific version" do
      its(:display_s) { is_expected.to eq("mono") }
    end

    context "with version 5.10" do
      subject { described_class.new(%w[5.10]) }

      its(:display_s) { is_expected.to eq("mono = 5.10") }
    end

    context "with version 5.10+" do
      subject { described_class.new(%w[5.10+]) }

      its(:display_s) { is_expected.to eq("mono >= 5.10") }
    end
  end

  describe "#satisfied?" do
    subject { described_class.new(%w[5.10]) }

    it "returns false if no `mono` executable can be found" do
      allow(File).to receive(:executable?).and_return(false)
      expect(subject).not_to be_satisfied
    end

    context "when #possible_mono contains paths" do
      let(:path) { mktmpdir }
      let(:mono) { path/"bin/mono" }

      def setup_mono_with_version(version)
        FileUtils.mkdir path/"bin"
        IO.write mono, <<~SH
          #!/bin/sh
          echo "Mono JIT compiler version #{version} (branch/commit Tue Jul 24 10:18:50 EDT 2018)
          Copyright (C) 2002-2014 Novell, Inc, Xamarin Inc and Contributors. www.mono-project.com
            TLS:           normal
            SIGSEGV:       altstack
            Notification:  kqueue
            Architecture:  amd64
            Disabled:      none
            Misc:          softdebug
            Interpreter:   yes
            LLVM:          yes(branch/commit)
            GC:            sgen (concurrent by default)"
        SH
        FileUtils.chmod "+x", mono
      end

      before do
        allow(subject).to receive(:possible_mono).and_return([mono])
      end

      context "and 5.10 is required" do
        subject { described_class.new(%w[5.10]) }

        it "returns false if all are lower" do
          setup_mono_with_version "5.6"
          expect(subject).not_to be_satisfied
        end

        it "returns true if one is equal" do
          setup_mono_with_version "5.10"
          expect(subject).to be_satisfied
        end

        it "returns false if all are higher" do
          setup_mono_with_version "5.12"
          expect(subject).not_to be_satisfied
        end
      end

      context "and 5.10+ is required" do
        subject { described_class.new(%w[5.10+]) }

        it "returns false if all are lower" do
          setup_mono_with_version "5.6"
          expect(subject).not_to be_satisfied
        end

        it "returns true if one is equal" do
          setup_mono_with_version "5.10"
          expect(subject).to be_satisfied
        end

        it "returns true if one is higher" do
          setup_mono_with_version "5.12"
          expect(subject).to be_satisfied
        end
      end
    end
  end
end
