# frozen_string_literal: true

module FormulaKeeper
  def self.path(f)
    HOMEBREW_KEEP_FORMULAE/f.name
  end

  def self.keep(f)
    HOMEBREW_KEEP_FORMULAE.mkpath
    FileUtils.touch path(f) if !keeping?(f) && keepable?(f)
  end

  def self.unkeep(f)
    FileUtils.rm_rf path(f) if keeping?(f)
    HOMEBREW_KEEP_FORMULAE.rmdir_if_possible
  end

  def self.keeping?(f)
    path(f).exist?
  end

  def self.keepable?(f)
    !f.installed_prefixes.empty?
  end
end
