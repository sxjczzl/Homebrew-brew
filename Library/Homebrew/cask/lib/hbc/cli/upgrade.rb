module Hbc
  class CLI
    class Upgrade < Base
      def self.run(*args)
        casks = Hbc.installed
        force = args.include? "--force"
        skip_cask_deps = args.include? "--skip-cask-deps"
        require_sha = args.include? "--require-sha"
        outdated=[]
        casks.each do |cask|
          if cask.outdated?
            if cask.pinned?
              opoo "#{cask} pinned, not upgrading"
            else
              outdated.push(cask.to_s)
            end
          end
        end
        retval = Reinstall.install_casks outdated, force, skip_cask_deps, require_sha
      end

      def self.help
        "upgrade all outdated Casks ( without those pinned )"
      end

    end
  end
end
