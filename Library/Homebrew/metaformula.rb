require "formula"

# A meta-formula is a special kind of formula which will
# * Allow bulk management of several related formulae (only `install` now)
# * extend the semantics of 'dependency' to casks
#
# As a result, {MetaFormula} differs from {Formula} in that
# * `url` is not mandatory
# * `version` is mandatory, (since it can not be deduced from `url` now)
# * the keg directory can be empty now (which will influence the "empty installation" check in audit.rb)
# * .stable only serves as attribute reader (not receiving blocks) in {MetaFormula}
# * .devel, .head, .bottle, and .patch are disabled
# * `depends_on` now accepts :cask, e.g.
#     depends_on :cask => "cask_name"
#

class MetaFormula < Formula
  # @private
  # Differs from {Formula#initialize} in that:
  # * `spec` argument can only be :stable
  # * @specs only contains @stable
  # * @active_spec is always @stable
  # * @active_spec_sym is always :sym
  def initialize(name, path, spec, alias_path: nil)
    raise FormulaSpecificationError, "metaformulae only accept :stable spec" if spec != :stable

    @name = name
    @path = path
    @alias_path = alias_path
    @alias_name = if alias_path
      File.basename(alias_path)
    end
    @revision = self.class.revision || 0
    @version_scheme = self.class.version_scheme || 0

    @tap = if path == Formulary.core_path(name)
      CoreTap.instance
    else
      Tap.from_path(path)
    end

    @full_name = full_name_with_optional_tap(name)
    @full_alias_name = full_name_with_optional_tap(@alias_name)

    @stable = self.class.stable
    @stable.owner = self

    @active_spec = @stable
    @active_spec_sym = :stable

    validate_attributes!
    @build = active_spec.build
    @pin = FormulaPin.new(self)
    @follow_installed_alias = true
    @prefix_returns_versioned_prefix = false
    @oldname_lock = nil
  end

  # Ignore url error in attribute validation
  def validate_attributes!
    is_empty = ->(str) { str.nil? || str.empty? || str =~ /\s/ }

    raise FormulaValidationError.new(full_name, :name, name) if is_empty.call(name)

    ver = version.respond_to?(:to_str) ? version.to_str : version
    raise FormulaValidationError.new(full_name, :version, ver) if is_empty.call(ver)
  end

  # Metaformula is not designed to be bottled for now
  def bottle_disabled?
    true
  end

  def cask_deps
    requirements.select { |req| req.is_a? CaskRequirement }
  end

  class << self
    # DSL not designed to be used in MetaFormula for now are disabled to avoid undefined behaviors
    # This is subject to change if certain functions should be assigned to them.

    # @private
    def specs
      @specs ||= [stable].freeze
    end

    # {.stable} only serves as attribute reader (not receiving blocks) in {MetaFormula}
    def stable
      @stable ||= SoftwareSpec.new
    end

    # {.devel}, {.head}, {.bottle} and {.patch} are disabled in {MetaFormula}
    def devel
      raise "`devel` DSL is disabled in MetaFormula"
    end

    def head
      raise "`head` DSL is disabled in MetaFormula"
    end

    def bottle
      raise "`bottle` DSL is disabled in MetaFormula"
    end

    def patch
      raise "`patch` DSL is disabled in MetaFormula"
    end
  end
end
