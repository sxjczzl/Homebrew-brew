module Hbc
  class CLI
    class Outdated < Base
      def self.run(*args)
        @greedy = true if args.delete("--greedy")

        cask_tokens = cask_tokens_from(args)
        if cask_tokens.empty?
          check_installed
        else
          check_casks(cask_tokens)
        end
      end

      def self.help
        "Show Casks that have an updated version available"
      end

      def self.check_installed
        Hbc.installed.each(&method(:check_outdated))
      end

      def self.check_casks(cask_tokens)
        cask_tokens.each do |cask_token|
          begin
            cask = Hbc.load(cask_token)
            if cask.installed?
              check_outdated(cask)
            else
              opoo "#{cask} is not installed"
            end
          rescue CaskUnavailableError => e
            onoe e
          end
        end
      end

      def self.check_outdated(cask)
        odebug "Checking outdated for Cask #{cask.token}"
        return unless cask.outdated?(@greedy)
        if $stdout.tty?
          puts "#{cask.token}: (#{cask.latest_installed_version}) != #{cask.version}"
        else
          puts cask.token
        end
      end
    end
  end
end
