# Used to track formulae that cannot be installed at the same time
FormulaConflict = Struct.new(:name, :reason)

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
