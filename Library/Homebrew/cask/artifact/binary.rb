# typed: true
# frozen_string_literal: true

require "cask/artifact/symlinked"

require "extend/hash_validator"
using HashValidator

module Cask
  module Artifact
    # Artifact corresponding to the `binary` stanza.
    #
    # @api private
    class Binary < Symlinked
      def self.from_args(cask, *args)
        source, args = args

        if args
          raise CaskInvalidError unless args.respond_to?(:keys)

          args.assert_valid_keys!(:target, :shimscript)
        end

        args ||= {}

        new(cask, source, **args)
      end

      def initialize(cask, source, target: nil, shimscript: nil)
        super(cask, source, target: target)
        return if shimscript.nil?

        @shimscript_source = self.source
        @source_string = shimscript.to_s
        @source = cask.staged_path.join(shimscript)
      end

      def link(force: false, command: nil, **options)
        if @shimscript_source
          check_if_source_missing(@shimscript_source)

          check_if_target_exists(source) do
            next false unless force

            source.realpath.to_s.start_with?("#{cask.caskroom_path}/")
          end

          ohai "Creating shim script for '#{@shimscript_source.basename}' at '#{source}'"
          create_shimscript
        end

        super(force: force, command: command, **options)

        check_if_source_executable(source, command: command)
        check_if_source_executable(@shimscript_source, command: command) if @shimscript_source
      end

      def unlink(**options)
        super(**options)

        return if @shimscript_source.blank?

        ohai "Removing shim script '#{source}'"
        source.delete
      end

      def check_if_source_executable(source, command:)
        return if source.executable?

        if source.writable?
          FileUtils.chmod "+x", source
        else
          command.run!("/bin/chmod", args: ["+x", source], sudo: true)
        end
      end

      def create_shimscript
        source.dirname.mkpath

        File.write source, <<~EOS
          #!/bin/bash
          exec '#{@shimscript_source}' "$@"
        EOS
      end
    end
  end
end
