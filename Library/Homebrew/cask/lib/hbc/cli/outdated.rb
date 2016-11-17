module Hbc
  class CLI
    class Outdated < Base
      def self.run(*args)
        casks = Hbc.installed
        casks.each do |cask|
          check_outdated(cask)
        end
      end

      def self.help
        "check Casks that outdated"
      end

      def self.check_outdated(cask)
        if cask.outdated?
          puts "#{cask.token}: (#{cask.installed_latest_version}) < #{cask.version}"
        end
      end

    end
  end
end
