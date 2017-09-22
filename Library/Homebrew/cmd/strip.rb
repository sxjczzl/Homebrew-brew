#:  * `strip` [`--all`]
#:    Strip binary executables and libraries to reduce their size.
#:
#:    If `--all` is passed, strip all installed formulae.

module Homebrew
  module_function

  def binary_object?(file)
    f = Pathname.new file
    return false unless f.file?
    return true if f.extname == ".a"
    if OS.mac?
      f.dylib? || f.mach_o_executable? || f.mach_o_bundle?
    else
      false
    end
  end

  def strip_keg(keg)
    binaries = Dir[keg/"**/*"].select do |f|
      !File.symlink?(f) && binary_object?(f)
    end
    return if binaries.empty?

    puts "  #{keg} (#{keg.abv})"
    not_writable = binaries.reject { |f| File.writable? f }
    keg.lock do
      begin
        safe_system "chmod", "u+w", *not_writable unless not_writable.empty?
        args = ["--strip-unneeded", "--preserve-dates"] unless OS.mac?
        system "strip", *args, *binaries, err: (:close unless ARGV.verbose?)
      ensure
        system "chmod", "u-w", *not_writable unless not_writable.empty?
      end
    end
    puts "  #{keg} (#{keg.abv})"
  end

  def strip_formula(formula)
    kegs = formula.installed_kegs
    return ofail "Formula not installed: #{formula.full_name}" if kegs.empty?
    ohai "Stripping #{formula.full_name}..."
    kegs.each { |keg| strip_keg keg }
  end

  def strip_formulae(formulae)
    formulae.each { |f| strip_formula f }
  end

  def strip
    odie "Command not found: strip" unless which "strip"
    if ARGV.include?("--all") || ARGV.include?("--installed")
      strip_formulae Formula.installed.sort
    else
      raise FormulaUnspecifiedError if ARGV.named.empty?
      strip_formulae ARGV.resolved_formulae.sort
    end
  end
end
