require "hbc/container/base"
require "hbc/utils"

module Hbc
  class Container
    class Gpg < Base
      def self.me?(criteria)
        criteria.extension(/^(gpg)$/)
      end

      def import_key
        if @cask.gpg.nil?
          raise CaskError, "Expected to find GPG public key. Cask '#{@cask}' must add `gpg :embedded, key_id: <id>' or 'gpg :embedded, key_url: <url>`."
        end

        if @cask.gpg.key_id
          Utils.gpg(args: ["--receive-keys", @cask.gpg.key_id], command: @command)
        elsif @cask.gpg.key_url
          Utils.gpg(args: ["--fetch-keys", @cask.gpg.key_url.to_s], command: @command)
        end
      end

      def extract
        unless Formula["gnupg"].any_version_installed?
          raise CaskError, "Formula 'gnupg' is not installed. Cask '#{@cask}' must add `depends_on formula: 'gnupg'`."
        end

        import_key

        Dir.mktmpdir do |unpack_dir|
          Utils.gpg(args: ["--batch", "--yes", "--output", Pathname(unpack_dir).join(@path.basename(".gpg")), "--decrypt", @path])

          extract_nested_inside(unpack_dir)
        end
      end
    end
  end
end
