# typed: false
# frozen_string_literal: true

require "cli/parser"
require "utils/github"

module Homebrew
  extend T::Sig

  module_function

  sig { returns(CLI::Parser) }
  def dispatch_build_bottle_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `dispatch-build-bottle` [<options>] <formula> [<formula> ...]

        Build bottles for these formulae with GitHub Actions.
      EOS
      flag   "--tap=",
             description: "Target tap repository (default: `homebrew/core`)."
      flag   "--issue=",
             description: "If specified, post a comment to this issue number if the job fails."
      flag   "--macos=",
             description: "Version of macOS the bottle should be built for."
      flag   "--workflow=",
             description: "Dispatch specified workflow (default: `dispatch-build-bottle.yml`)."
      switch "--linux",
             description: "Build a Linux bottle."
      switch "--linux-self-hosted",
             description: "Build a Linux bottle on a self hosted runner."
      switch "--upload",
             description: "Upload built bottles to Bintray."

      conflicts "--macos", "--linux", "--linux-self-hosted"

      min_named :formula
    end
  end

  def dispatch_build_bottle
    args = dispatch_build_bottle_args.parse

    os = if args.macos
      begin
        MacOS::Version.from_symbol(args.macos.to_sym)
      rescue MacOSVersionError
        MacOS::Version.new(args.macos)
      end
    elsif args.linux?
      "ubuntu-latest"
    elsif args.linux_self_hosted?
      "ubuntu-self-hosted"
    else
      odie "Must specify either --macos or --linux or --linux-self-hosted flag"
    end

    tap = Tap.fetch(args.tap || CoreTap.instance.name)
    user, repo = tap.full_name.split("/")

    workflow = args.workflow || "dispatch-build-bottle.yml"
    ref = "master"

    args.named.to_resolved_formulae.each do |formula|
      # Required inputs
      inputs = {
        formula: formula.name,
        os:      os.to_s,
      }

      # Optional inputs
      # These cannot be passed as nil to GitHub API
      inputs[:issue] = args.issue if args.issue
      inputs[:upload] = args.upload?.to_s if args.upload?

      ohai "Dispatching #{tap} bottling request of formula \"#{formula.name}\" for #{os}"
      GitHub.workflow_dispatch_event(user, repo, workflow, ref, inputs)
    end
  end
end
