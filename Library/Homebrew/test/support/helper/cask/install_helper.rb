require "test/support/helper/shutup"

module InstallHelper
  module_function

  extend Test::Helper::Shutup

  def install_without_artifacts(cask)
    Hbc::Installer.new(cask).tap do |i|
      shutup do
        i.download
        i.extract_primary_container
      end
    end
  end

  def self.install_with_caskfile(cask)
    Hbc::Installer.new(cask).tap do |i|
      shutup do
        i.save_caskfile
      end
    end
  end

  def self.install_without_artifacts_with_caskfile(cask)
    Hbc::Installer.new(cask).tap do |i|
      shutup do
        i.download
        i.extract_primary_container
        i.save_caskfile
      end
    end
  end
end
