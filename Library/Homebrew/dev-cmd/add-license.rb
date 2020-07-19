# frozen_string_literal: true

require "formula"
require "cli/parser"

module Homebrew
  module_function

  def add_license_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `add-license` [<options>] <formula> <license>

        Create a commit to add <license> to <formula>.
      EOS
      switch "-n", "--dry-run",
             description: "Print what would be done rather than doing it."
      switch "--no-audit",
             description: "Don't run `brew audit` before committing."
      switch "--strict",
             description: "Run `brew audit --strict` before committing."
      flag   "--message=",
             description: "Append <message> to the default commit message."
      switch :force
      switch :quiet
      switch :verbose
      switch :debug
      named 2
    end
  end

  def add_license
    add_license_args.parse

    # As this command is simplifying user-run commands then let's just use a
    # user path, too.
    ENV["PATH"] = ENV["HOMEBREW_PATH"]

    name = args.named.first
    formula = Formula[name]
    current_license = formula.license

    old_contents = File.read(formula.path) unless args.dry_run?

    license = args.named.second

    if current_license.nil?
      formula_spec = formula.stable
      hash_type, old_hash = if (checksum = formula_spec.checksum)
        [checksum.hash_type, checksum.hexdigest]
      end

      old = if formula.path.read.include?("stable do\n")
        # insert replacement revision after homepage
        <<~EOS
          homepage "#{formula.homepage}"
        EOS
      elsif hash_type
        # insert replacement revision after hash
        <<~EOS
          #{hash_type} "#{old_hash}"
        EOS
      else
        # insert replacement revision after :revision
        <<~EOS
          :revision => "#{formula_spec.specs[:revision]}"
        EOS
      end
      replacement = old + "  license \"#{license}\"\n"

    elsif args.force?
      if license == current_license
        odie <<~EOS
          The new license and old license are both #{license}.
        EOS
      end
      old = "license \"#{current_license}\""
      replacement = "license \"#{license}\""
    else
      odie <<~EOS
        #{formula} already has a license: #{license}
        Use --force to change the current license.
      EOS
    end

    if args.dry_run?
      ohai "replace #{old.inspect} with #{replacement.inspect}" unless args.quiet?
    else
      Utils::Inreplace.inreplace(formula.path) do |s|
        s.gsub!(old, replacement)
      end
    end

    run_audit(formula, old_contents)

    message = "#{formula.name}: #{current_license ? "change" : "add"} license #{args.message}"
    if args.dry_run?
      ohai "git commit --no-edit --verbose --message=#{message} -- #{formula.path}"
    else
      formula.path.parent.cd do
        safe_system "git", "commit", "--no-edit", "--verbose",
                    "--message=#{message}", "--", formula.path
      end
    end
  end

  def run_audit(formula, old_contents)
    if args.dry_run?
      if args.no_audit?
        ohai "Skipping `brew audit`"
      elsif args.strict?
        ohai "brew audit --strict #{formula.path.basename}"
      else
        ohai "brew audit #{formula.path.basename}"
      end
      return
    end
    failed_audit = false
    if args.no_audit?
      ohai "Skipping `brew audit`"
    elsif args.strict?
      system HOMEBREW_BREW_FILE, "audit", "--strict", formula.path
      failed_audit = !$CHILD_STATUS.success?
    else
      system HOMEBREW_BREW_FILE, "audit", formula.path
      failed_audit = !$CHILD_STATUS.success?
    end
    return unless failed_audit

    formula.path.atomic_write(old_contents)
    odie "`brew audit` failed!"
  end
end
