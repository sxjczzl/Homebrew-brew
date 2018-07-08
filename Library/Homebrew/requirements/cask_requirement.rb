require "requirement"
require "hbc/cask_loader"

class CaskRequirement < Requirement
  fatal true

  def initialize(tags = [])
    @cask = @name = tags.shift
    raise UnsatisfiedRequirements, message unless @cask
    @cask_loaded = Hbc::CaskLoader.load(@cask)
    super(tags)
  end

  satisfy(build_env: false) { installed? && !outdated? }

  def installed?
    @cask_loaded.installed?
  end

  def outdated?
    @cask_loaded.outdated?
  end

  def install
    system(HOMEBREW_BREW_FILE, "cask", "install", @cask)
  end

  def upgrade
    system(HOMEBREW_BREW_FILE, "cask", "upgrade", @cask)
  end

  def message
    if @cask
      "Cask requirement #{@cask} is not met"
    else
      "MetaFormula DSL `depends_on :cask => \"cask_name\"` requires a cask_name"
    end
  end
end
