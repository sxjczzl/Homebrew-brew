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

        @shimscript_source = @source
        @source_string = shimscript.to_s
        @source = cask.staged_path.join(shimscript)
      end

      def link(command: nil, **options)
        if @shimscript_source
          File.write source, <<~EOS
            #!/bin/bash
            exec '#{@shimscript_source}' "$@"
          EOS
        end

        super(command: command, **options)
        return if source.executable?

        if source.writable?
          FileUtils.chmod "+x", source
        else
          command.run!("/bin/chmod", args: ["+x", source], sudo: true)
        end
      end
    end
  end
end
