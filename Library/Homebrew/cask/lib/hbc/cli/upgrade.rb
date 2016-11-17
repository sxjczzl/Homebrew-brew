module Hbc
  class CLI
    class Upgrade < Base
      def self.run(*args)
        casks = Hbc.installed
        ignore_update_check = args.include? "--ignore-update-check"
        force = args.include? "--force"
        skip_cask_deps = args.include? "--skip-cask-deps"
        require_sha = args.include? "--require-sha"
        args.delete("--ignore-update-check")
        args.delete("--force")
        args.delete("--skip-cask-deps")
        args.delete("--require-sha")
        cask_tokens = args.any? ? list(*args) : Hbc.installed.map(&:to_s)
        outdated=[]
        cask_tokens.each do |cask_token|
          cask = Hbc.load(cask_token)
          if cask.outdated?
            if cask.pinned?
              opoo "#{cask_token} pinned, not upgrading"
            elsif ignore_update_check and cask.auto_update?
              opoo "#{cask_token} have built-in auto-update, no need for upgrading through CLI. Use --ignore-update-check to ignore this check"
            else
              outdated.push(cask_token)
            end
          end
        end
        retval = Reinstall.install_casks outdated, force, skip_cask_deps, require_sha
        raise CaskError, "nothing to install" if retval.nil?
        raise CaskError, "install incomplete" unless retval
      end

      def self.help
        "upgrade all outdated Casks ( without those pinned )"
      end

      def self.list(*cask_tokens)
        result_tokens=[]
        cask_tokens.each do |cask_token|
          odebug "Listing files for Cask #{cask_token}"
          begin
            cask = Hbc.load(cask_token)
            if cask.installed?
              result_tokens.push cask.token
            else
              opoo "#{cask} is not installed"
            end
          rescue CaskUnavailableError => e
            onoe e
          end
        end

        result_tokens
      end

    end
  end
end
