require "version"

class PkgVersion
  include Comparable

  RX = /\A(.+?)(?:_(\d+))?\z/

  attr_reader :version, :formula_revision

  def self.parse(path)
    _, version, formula_revision = *path.match(RX)
    version = Version.create(version)
    new(version, formula_revision.to_i)
  end

  def initialize(version, formula_revision)
    @version = version
    @formula_revision = formula_revision
  end

  def head?
    version.head?
  end

  def to_s
    if formula_revision > 0
      "#{version}_#{formula_revision}"
    else
      version.to_s
    end
  end
  alias_method :to_str, :to_s

  def <=>(other)
    return unless PkgVersion === other
    (version <=> other.version).nonzero? || formula_revision <=> other.formula_revision
  end
  alias_method :eql?, :==

  def hash
    version.hash ^ formula_revision.hash
  end
end
