module Hbc
  class CLI
    class Outdated < Base
      def self.run(*args)
        @options = {}
        @options[:greedy] = true if args.delete("--greedy")
        @options[:quiet] = true if args.delete("--quiet")
        @options[:verbose] = true if args.delete("--verbose") || Hbc.verbose
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

      def self.show_version_detail?
        @options[:verbose] || (!@options[:quiet] && $stdout.tty?)
      end

      def self.check_outdated(cask)
        odebug "Checking outdated for Cask #{cask.token}"
        return unless cask.outdated?(@options[:greedy])
        if show_version_detail?
          puts "#{cask.token}: (#{cask.latest_installed_version}) != #{cask.version}"
        else
          puts cask.token
        end
      end
    end
  end
end
