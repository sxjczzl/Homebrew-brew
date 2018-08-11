describe Hbc::Quarantine, :cask do
  describe "by default" do
    it "quarantines Cask installs" do
      Hbc::CLI::Install.run("local-transmission")

      expect(Hbc::CaskLoader.load(cask_path("local-transmission"))).to be_installed
      expect(Hbc::Config.global.appdir.join("Transmission.app")).to be_a_directory

      expect(
        described_class.detect(Hbc::Config.global.appdir.join("Transmission.app")),
      ).to be true
    end

    it "quarantines Cask fetches" do
      Hbc::CLI::Fetch.run("local-transmission")
      local_transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))
      cached_location = Hbc::Download.new(local_transmission, force: false, quarantine: false).perform

      expect(
        described_class.detect(cached_location),
      ).to be true
    end

    it "quarantines non-DMG Cask installs too" do
      Hbc::CLI::Install.run("container-tar-gz")

      expect(Hbc::CaskLoader.load(cask_path("container-tar-gz"))).to be_installed
      expect(Hbc::Config.global.appdir.join("container")).to exist

      expect(
        described_class.detect(Hbc::Config.global.appdir.join("container")),
      ).to be true
    end
  end

  describe "when disabled" do
    it "does not quarantine Cask installs" do
      Hbc::CLI::Install.run("local-transmission", "--no-quarantine")

      expect(Hbc::CaskLoader.load(cask_path("local-transmission"))).to be_installed
      expect(Hbc::Config.global.appdir.join("Transmission.app")).to be_a_directory

      expect(
        described_class.detect(Hbc::Config.global.appdir.join("Transmission.app")),
      ).to be false
    end

    it "does not quarantine Cask fetches" do
      Hbc::CLI::Fetch.run("local-transmission", "--no-quarantine")
      local_transmission = Hbc::CaskLoader.load(cask_path("local-transmission"))
      cached_location = Hbc::Download.new(local_transmission, force: false, quarantine: false).perform

      expect(
        described_class.detect(cached_location),
      ).to be false
    end

    it "does not quarantine the Cask install even with non-DMG containers" do
      Hbc::CLI::Install.run("container-tar-gz", "--no-quarantine")

      expect(Hbc::CaskLoader.load(cask_path("container-tar-gz"))).to be_installed
      expect(Hbc::Config.global.appdir.join("container")).to exist

      expect(
        described_class.detect(Hbc::Config.global.appdir.join("container")),
      ).to be false
    end
  end
end
