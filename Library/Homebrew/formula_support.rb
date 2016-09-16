# Used to track formulae that cannot be installed at the same time
FormulaConflict = Struct.new(:name, :reason)

# A dummy KegOnlyReason class that adds `keg_only` compatibility across non-macOS platforms
class KegOnlyReason
  def initialize(reason, explanation)
    @reason = reason
    @explanation = explanation
  end

  def valid?
    true
  end

  def to_s
    return @explanation unless @explanation.empty?
    @reason
  end
end

# Used to annotate formulae that don't require compiling or cannot build bottle.
class BottleDisableReason
  SUPPORTED_TYPES = [:unneeded, :disable]

  def initialize(type, reason)
    @type = type
    @reason = reason
  end

  def unneeded?
    @type == :unneeded
  end

  def valid?
    SUPPORTED_TYPES.include? @type
  end

  def to_s
    if @type == :unneeded
      "This formula doesn't require compiling."
    else
      @reason
    end
  end
end

require "extend/os/formula_support"
