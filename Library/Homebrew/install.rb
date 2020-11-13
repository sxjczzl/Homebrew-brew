# typed: true
# frozen_string_literal: true

require "diagnostic"
require "fileutils"
require "hardware"
require "development_tools"

module Homebrew
  # Helper module for performing (pre-)install checks.
  #
  # @api private
  module Install
    module_function

    def perform_preinstall_checks(all_fatal: false, cc: nil)
      check_flavour_matches_architecture
      check_cpu
      attempt_directory_creation
      check_cc_argv(cc)
      Diagnostic.checks(:supported_configuration_checks, fatal: all_fatal)
      Diagnostic.checks(:fatal_preinstall_checks)
    end
    alias generic_perform_preinstall_checks perform_preinstall_checks
    module_function :generic_perform_preinstall_checks

    def perform_build_from_source_checks(all_fatal: false)
      Diagnostic.checks(:fatal_build_from_source_checks)
      Diagnostic.checks(:build_from_source_checks, fatal: all_fatal)
    end

    def check_flavour_matches_architecture
      homebrew_flavour = HOMEBREW_REPOSITORY.cd do
        Utils.popen_read("git", "config", "--get", "homebrew.flavour").chomp.presence
      end

      if !homebrew_flavour ||
         (Hardware::CPU.intel? && homebrew_flavour == "x86_64") ||
         (Hardware::CPU.arm? && homebrew_flavour == "arm64")
        return
      end

      error_title = "This Homebrew installation in #{HOMEBREW_PREFIX} only works on #{homebrew_flavour} processors."
      odie error_title unless Hardware::CPU.arm?

      ohai "Checking whether Rosetta is installed"
      rosetta_installed = quiet_system(
        "/usr/bin/swift",
        "#{HOMEBREW_REPOSITORY}/Library/Homebrew/utils/rosetta_installed.swift",
      )
      rosetta_instructions = if rosetta_installed
        <<~EOS
          To use it, you can:
          - run your Terminal from Rosetta 2 or
          - run 'arch -x86_64 brew' instead of 'brew'.
        EOS
      else
        "To use it, you need to install Rosetta 2 first."
      end

      odie <<~EOS
        #{error_title}
        #{rosetta_instructions}
        Or create a new installation in #{HOMEBREW_MACOS_ARM_DEFAULT_PREFIX} using one of the
        "Alternative Installs" from:
          #{Formatter.url("https://docs.brew.sh/Installation")}
        You can migrate your previously installed formula list with:
          brew bundle dump
      EOS
    end

    def check_cpu
      return if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?

      # Handled by check_for_unsupported_arch in extend/os/mac/diagnostic.rb
      return if Hardware::CPU.arm?

      return unless Hardware::CPU.ppc?

      odie <<~EOS
        Sorry, Homebrew does not support your computer's CPU architecture!
        For PowerPC Mac (PPC32/PPC64BE) support, see:
          #{Formatter.url("https://github.com/mistydemeo/tigerbrew")}
      EOS
    end
    private_class_method :check_cpu

    def attempt_directory_creation
      Keg::MUST_EXIST_DIRECTORIES.each do |dir|
        FileUtils.mkdir_p(dir) unless dir.exist?

        # Create these files to ensure that these directories aren't removed
        # by the Catalina installer.
        # (https://github.com/Homebrew/brew/issues/6263)
        keep_file = dir/".keepme"
        FileUtils.touch(keep_file) unless keep_file.exist?
      rescue
        nil
      end
    end
    private_class_method :attempt_directory_creation

    def check_cc_argv(cc)
      return unless cc

      @checks ||= Diagnostic::Checks.new
      opoo <<~EOS
        You passed `--cc=#{cc}`.
        #{@checks.please_create_pull_requests}
      EOS
    end
    private_class_method :check_cc_argv
  end
end

require "extend/os/install"
