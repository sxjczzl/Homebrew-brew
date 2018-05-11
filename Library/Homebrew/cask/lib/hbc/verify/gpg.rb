require "formula"
require "hbc/utils"

module Hbc
  module Verify
    class Gpg
      def self.me?(cask)
        !cask.gpg.nil?
      end

      attr_reader :cask, :downloaded_path

      def initialize(cask, downloaded_path, command = Hbc::SystemCommand)
        @command = command
        @cask = cask
        @downloaded_path = downloaded_path
      end

      def installed?
        Formula["gnupg"].any_version_installed?
      end

      def fetch_sig(_force = false)
        url = cask.gpg.signature

        signature_filename = "#{Digest::SHA2.hexdigest(url.to_s)}.asc"
        signature_file = Hbc.cache/signature_filename

        unless signature_file.exist?
          ohai "Fetching GPG signature '#{cask.gpg.signature}'."
          curl_download cask.gpg.signature, to: signature_file
        end

        FileUtils.ln_sf signature_filename, Hbc.cache/"#{cask.token}--#{cask.version}.asc"

        signature_file
      end

      def verify
        unless installed?
          ohai "Formula 'gnupg' is not installed, skipping verification of GPG signature for Cask '#{cask}'."
          return
        end

        if cask.gpg.signature == :embedded
          ohai "Skipping verification of embedded GPG signature for Cask '#{cask}'."
          return
        end

        if cask.gpg.signature.is_a?(Pathname)
          ohai "Skipping verification of GPG signature included in container for Cask '#{cask}'."
          return
        end

        if cask.gpg.key_id
          Utils.gpg(args: ["--receive-keys", cask.gpg.key_id], command: @command, print_stderr: false)
        elsif cask.gpg.key_url
          Utils.gpg(args: ["--fetch-keys", cask.gpg.key_url.to_s], command: @command, print_stderr: false)
        end

        sig = fetch_sig

        ohai "Verifying GPG signature for Cask '#{cask}'."

        Utils.gpg(args: ["--verify", sig, downloaded_path], command: @command, print_stderr: false)
      end
    end
  end
end
