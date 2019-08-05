# frozen_string_literal: true

require "ostruct"

module Homebrew
  module CLI
    class Args < OpenStruct
      # undefine tap to allow --tap argument
      undef tap

      def initialize(argv:)
        super
        @argv = argv
      end

      def named
        # TODO: use @instance variable to ||= cache when moving to CLI::Parser
        self - options_only
      end

      def options_only
        select { |arg| arg.start_with?("-") }
      end

      def formulae
        require "formula"
        # TODO: use @instance variable to ||= cache when moving to CLI::Parser
        (downcased_unique_named - casks).map do |name|
          if name.include?("/") || File.exist?(name)
            Formulary.factory(name, spec)
          else
            Formulary.find_with_priority(name, spec)
          end
        end.uniq(&:name)
      end

      def resolved_formulae
        require "formula"
        # TODO: use @instance variable to ||= cache when moving to CLI::Parser
        (downcased_unique_named - casks).map do |name|
          Formulary.resolve(name, spec: spec(nil))
        end.uniq(&:name)
      end

      def casks
        # TODO: use @instance variable to ||= cache when moving to CLI::Parser
        downcased_unique_named.grep HOMEBREW_CASK_TAP_CASK_REGEX
      end

      def kegs
        require "keg"
        require "formula"
        require "missing_formula"
        # TODO: use @instance variable to ||= cache when moving to CLI::Parser
        downcased_unique_named.map do |name|
          raise UsageError if name.empty?

          rack = Formulary.to_rack(name.downcase)

          dirs = rack.directory? ? rack.subdirs : []

          if dirs.empty?
            if (reason = Homebrew::MissingFormula.suggest_command(name, "uninstall"))
              $stderr.puts reason
            end
            raise NoSuchKegError, rack.basename
          end

          linked_keg_ref = HOMEBREW_LINKED_KEGS/rack.basename
          opt_prefix = HOMEBREW_PREFIX/"opt/#{rack.basename}"

          begin
            if opt_prefix.symlink? && opt_prefix.directory?
              Keg.new(opt_prefix.resolved_path)
            elsif linked_keg_ref.symlink? && linked_keg_ref.directory?
              Keg.new(linked_keg_ref.resolved_path)
            elsif dirs.length == 1
              Keg.new(dirs.first)
            else
              f = if name.include?("/") || File.exist?(name)
                Formulary.factory(name)
              else
                Formulary.from_rack(rack)
              end

              unless (prefix = f.installed_prefix).directory?
                raise MultipleVersionsInstalledError, rack.basename
              end

              Keg.new(prefix)
            end
          rescue FormulaUnavailableError
            raise <<~EOS
              Multiple kegs installed to #{rack}
              However we do not know which one you refer to.
              Please delete (with rm -rf!) all but one and then try again.
            EOS
          end
        end
      end

      def value(name)
        arg_prefix = "--#{name}="
        flag_with_value = find { |arg| arg.start_with?(arg_prefix) }
        flag_with_value&.delete_prefix(arg_prefix)
      end

      def force?
        flag? "--force"
      end

      def quiet?
        #TODO remove with refactor for args
        args.quiet?
      end

      def debug?
        flag?("--debug") || !ENV["HOMEBREW_DEBUG"].nil?
      end

      def build_stable?
        !(include?("--HEAD") || include?("--devel"))
      end

      def flag?(flag)
        options_only.include?(flag) || switch?(flag[2, 1])
      end

      private

      def spec(default = :stable)
        if include?("--HEAD")
          :head
        elsif include?("--devel")
          :devel
        else
          default
        end
      end

      def downcased_unique_named
        # Only lowercase names, not paths, bottle filenames or URLs
        # TODO: use @instance variable to ||= cache when moving to CLI::Parser
        named.map do |arg|
          if arg.include?("/") || arg.end_with?(".tar.gz") || File.exist?(arg)
            arg
          else
            arg.downcase
          end
        end.uniq
      end

    end
  end
end
