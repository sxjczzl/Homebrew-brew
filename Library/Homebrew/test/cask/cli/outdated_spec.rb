require "utils"

describe Hbc::CLI::Outdated, :cask do
  let(:args) { [] }

  describe ".run" do
    let(:cask_tokens) { %w[local-caffeine local-transmission] }
    let(:casks) { cask_tokens.map { |c| Hbc.load(c) } }

    before {
      casks.each do |c|
        InstallHelper.install_with_caskfile(c)
      end
    }

    context "when nothing is outdated" do
      it "displays nothing" do
        expect { Hbc::CLI::Outdated.run }
          .to not_to_output.to_stdout
      end
    end

    context "when an outdated Cask is installed" do
      let (:cask) { casks[0] }

      before(:each) {
        allow(cask).to receive(:version).and_return("2.0.0")
        InstallHelper.install_with_caskfile(cask)
      }

      context "and $stdout is a TTY" do
        before(:each) do
          allow_any_instance_of(StringIO).to receive(:tty?).and_return(true)
        end

        it "displays the name and version of the outdated Cask" do
          expect { Hbc::CLI::Outdated.run }
            .to output("local-caffeine: (2.0.0) != 1.2.3\n").to_stdout
        end

        it "quietly displays the name of the outdated Cask" do
          expect { Hbc::CLI::Outdated.run("--quiet") }
            .to output("local-caffeine\n").to_stdout
        end

        it "verbosly displays the name and version of the outdated Cask" do
          expect { Hbc::CLI::Outdated.run("--verbose") }
            .to output("local-caffeine: (2.0.0) != 1.2.3\n").to_stdout
        end
      end

      context "and $stdout is not a TTY" do
        before(:each) do
          allow_any_instance_of(StringIO).to receive(:tty?).and_return(false)
        end

        it "displays the name of the outdated Cask" do
          expect { Hbc::CLI::Outdated.run }
            .to output("local-caffeine\n").to_stdout
        end

        it "quietly displays the name of the outdated Cask" do
          expect { Hbc::CLI::Outdated.run("--quiet") }
            .to output("local-caffeine\n").to_stdout
        end

        it "verbosly displays the name and version of the outdated Cask" do
          expect { Hbc::CLI::Outdated.run("--verbose") }
            .to output("local-caffeine: (2.0.0) != 1.2.3\n").to_stdout
        end
      end
    end

    context "when an auto_updates Cask is installed" do
      let (:cask) { Hbc.load("auto-updates") }

      before(:each) {
        InstallHelper.install_with_caskfile(cask)
        allow(cask).to receive(:version).and_return("3.0.0")
        InstallHelper.install_with_caskfile(cask)
      }

      it "does not display the outdated cask" do
        expect { Hbc::CLI::Outdated.run }
          .to not_to_output.to_stdout
      end

      it "greedily displays the outdated cask" do
        expect { Hbc::CLI::Outdated.run("--greedy") }
          .to output("auto-updates\n").to_stdout
      end
    end

    context "when a version :latest Cask is installed" do
      let (:cask) { Hbc.load("version-latest") }

      before(:each) {
        allow(cask).to receive(:version).and_return("1.0.0")
        InstallHelper.install_with_caskfile(cask)
      }

      it "does not display the outdated cask" do
        expect { Hbc::CLI::Outdated.run }
          .to not_to_output.to_stdout
      end

      it "greedily displays the outdated cask" do
        expect { Hbc::CLI::Outdated.run("--greedy") }
          .to output("version-latest\n").to_stdout
      end
    end
  end
end
