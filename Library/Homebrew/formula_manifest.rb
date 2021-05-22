# typed: false
# frozen_string_literal: true

require "build_options"
require "software_spec"

# Version of OpenStruct that errors on invalid method calls
# @api private
class StrictOpenStruct < OpenStruct
  def method_missing(name, *)
    raise NoMethodError, "undefined method `#{name}` for #{self.class}" unless @table.key?(name)

    super
  end

  def respond_to_missing?(*)
    true
  end

  def to_ary
    [self]
  end
end

# Contains information about a {Formula} to allow it to be installed
# without needing an actual formula file.
# @api private
class FormulaManifest < StrictOpenStruct
  extend T::Sig

  undef tap

  attr_accessor :force_bottle

  def initialize(hash, path)
    hash["path"] = path
    hash["tap"] = Tap.fetch(hash["tap"])
    hash["build"] = BuildOptions.new [], hash["options"]
    hash["version"] = Version.new(hash["versions"]["stable"])
    hash["options"] = Options.create(hash["options"])

    # Rename certain items to add "?"
    %w[deprecated disabled bottle_disabled keg_only].each do |key|
      hash["#{key}?"] = hash.delete key if hash.key? key
    end

    # Let's not bother about dealing with HEAD versions yet
    hash["latest_head_version"] = nil

    # Ignoring HEAD for now...
    hash["head?"] = false
    hash["head"] = nil
    hash["stable"] = StrictOpenStruct.new({
      version: hash["version"],
    })
    hash["active_spec_sym"] = :stable

    # This isn't present in the hash yet
    hash["service?"] = false
    hash["plist"] = nil

    # Some more placeholders
    hash["local_bottle_path"] = nil
    hash["deprecated_flags"] = []
    hash["deprecated_options"] = []
    hash["runtime_installed_formula_dependents"] = []

    # Aliases (these should probably be changed in the JSON file rather than here)
    hash["bottle_unneeded?"] = hash["bottle_disabled?"]
    hash["bottled?"] = hash["versions"]["bottle"]
    hash["deps"] = hash["dependencies"]
    hash["recursive_dependencies"] = hash["dependencies"]
    hash["specified_path"] = hash["path"]

    hash["conflicts"] = hash["conflicts_with"].map do |conflict|
      StrictOpenStruct.new({ name: conflict })
    end

    bottle_spec = BottleSpecification.new
    bottle_spec.root_url hash["bottle"]["stable"]["root_url"]

    bottle_tag = MacOS.version.to_sym
    bottle_hash = hash["bottle"]["stable"]["files"][bottle_tag.to_s]
    bottle_spec.sha256 cellar: bottle_hash["cellar"][1..].to_sym, bottle_tag => bottle_hash["sha256"]

    formula_for_bottle = OpenStruct.new({
      name:        hash["name"],
      pkg_version: PkgVersion.new(hash["version"], hash["revision"]),
    })
    hash["bottle"] = Bottle.new formula_for_bottle, bottle_spec
    hash["bottle_specification"] = hash["bottle"]

    # Not yet sure what this does...
    @prefix_returns_versioned_prefix = false

    super(self.class.hash_to_recursive_openstruct hash)
  end

  def runtime_dependencies(read_from_tab: true, undeclared: true)
    []
  end

  def runtime_formula_dependencies(read_from_tab: true, undeclared: true)
    []
  end

  # No-op for now because I'm not worried about this
  def lock; end

  def unlock; end

  # If this {Formula} is installed.
  # This is actually just a check for if the {#latest_installed_prefix} directory
  # exists and is not empty.
  # @private
  def latest_version_installed?
    (dir = latest_installed_prefix).directory? && !dir.children.empty?
  end

  # The directory where the formula's installation or test logs will be written.
  # @private
  def logs
    HOMEBREW_LOGS + name
  end

  # The directory where the formula's binaries should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # Need to install into the {.bin} but the makefile doesn't `mkdir -p prefix/bin`?
  # <pre>bin.mkpath</pre>
  #
  # No `make install` available?
  # <pre>bin.install "binary1"</pre>
  def bin
    prefix/"bin"
  end

  # The directory where the formula's libraries should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>lib.install "example.dylib"</pre>
  def lib
    prefix/"lib"
  end

  # The directory where the formula's shared files should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # Need a custom directory?
  # <pre>(share/"concept").mkpath</pre>
  #
  # Installing something into another custom directory?
  # <pre>(share/"concept2").install "ducks.txt"</pre>
  #
  # Install `./example_code/simple/ones` to `share/demos`:
  # <pre>(share/"demos").install "example_code/simple/ones"</pre>
  #
  # Install `./example_code/simple/ones` to `share/demos/examples`:
  # <pre>(share/"demos").install "example_code/simple/ones" => "examples"</pre>
  def share
    prefix/"share"
  end

  # The directory where the formula's headers should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  #
  # No `make install` available?
  # <pre>include.install "example.h"</pre>
  def include
    prefix/"include"
  end

  # The directory where the formula's `sbin` binaries should be installed.
  # This is symlinked into `HOMEBREW_PREFIX` after installation or with
  # `brew link` for formulae that are not keg-only.
  # Generally we try to migrate these to {#bin} instead.
  def sbin
    prefix/"sbin"
  end

  # The directory where the formula's variable files should be installed.
  # This directory is not inside the `HOMEBREW_CELLAR` so it persists
  # across upgrades.
  def var
    HOMEBREW_PREFIX/"var"
  end

  # The directory where the formula's configuration files should be installed.
  # Anything using `etc.install` will not overwrite other files on e.g. upgrades
  # but will write a new file named `*.default`.
  # This directory is not inside the `HOMEBREW_CELLAR` so it persists
  # across upgrades.
  def etc
    (HOMEBREW_PREFIX/"etc").extend(InstallRenamed)
  end

  # {PkgVersion} of the linked keg for the formula.
  sig { returns(T.nilable(PkgVersion)) }
  def linked_version
    return unless linked?

    Keg.for(linked_keg).version
  end

  # Is the formula linked?
  def linked?
    linked_keg.symlink?
  end

  sig { void }
  def fetch_bottle_tab
    return unless bottled?

    bottle.fetch_tab
  end

  sig { returns(Hash) }
  def bottle_tab_attributes
    return {} unless bottled?

    T.must(bottle).tab_attributes
  end

  # The latest prefix for this formula. Checks for {#head} and then {#stable}'s {#prefix}
  # @private
  def latest_installed_prefix
    if (stable_prefix = prefix(pkg_version)).directory?
      stable_prefix
    else
      prefix
    end
  end

  # The {PkgVersion} for this formula with {version} and {#revision} information.
  sig { returns(PkgVersion) }
  def pkg_version
    PkgVersion.new(version, revision)
  end

  def prefix(v = pkg_version)
    versioned_prefix = versioned_prefix(v)
    if !@prefix_returns_versioned_prefix && v == pkg_version &&
       versioned_prefix.directory? && Keg.new(versioned_prefix).optlinked?
      opt_prefix
    else
      versioned_prefix
    end
  end

  # The parent of the prefix; the named directory in the cellar containing all
  # installed versions of this software.
  # @private
  sig { returns(Pathname) }
  def rack
    HOMEBREW_CELLAR/name
  end

  # @private
  # The link status symlink directory for this {Formula}.
  # You probably want {#opt_prefix} instead.
  def linked_keg
    linked_keg = possible_names.map { |name| HOMEBREW_LINKED_KEGS/name }
                               .find(&:directory?)
    return linked_keg if linked_keg.present?

    HOMEBREW_LINKED_KEGS/name
  end

  # Returns the prefix for a given formula version number.
  # @private
  def versioned_prefix(v)
    rack/v
  end

  # Is the formula linked to `opt`?
  def optlinked?
    opt_prefix.symlink?
  end

  sig { returns(Pathname) }
  def opt_prefix
    HOMEBREW_PREFIX/"opt"/name
  end

  sig { returns(Pathname) }
  def opt_bin
    opt_prefix/"bin"
  end

  sig { returns(Pathname) }
  def opt_include
    opt_prefix/"include"
  end

  sig { returns(Pathname) }
  def opt_lib
    opt_prefix/"lib"
  end

  sig { returns(Pathname) }
  def opt_libexec
    opt_prefix/"libexec"
  end

  sig { returns(Pathname) }
  def opt_sbin
    opt_prefix/"sbin"
  end

  sig { returns(Pathname) }
  def opt_share
    opt_prefix/"share"
  end

  sig { returns(Pathname) }
  def opt_pkgshare
    opt_prefix/"share"/name
  end

  sig { returns(Pathname) }
  def opt_elisp
    opt_prefix/"share/emacs/site-lisp"/name
  end

  sig { returns(Pathname) }
  def opt_frameworks
    opt_prefix/"Frameworks"
  end

  def any_version_installed?
    installed_prefixes.any? { |keg| (keg/Tab::FILENAME).file? }
  end

  # All currently installed prefix directories.
  # @private
  def installed_prefixes
    possible_names.map { |name| HOMEBREW_CELLAR/name }
                  .select(&:directory?)
                  .flat_map(&:subdirs)
                  .sort_by(&:basename)
  end

  # All currently installed kegs.
  # @private
  def installed_kegs
    installed_prefixes.map { |dir| Keg.new(dir) }
  end

  def old_installed_formulae
    # Let's just return an empty array for now...
    []
  end

  def migration_needed?
    return false unless oldname
    return false if rack.exist?

    old_rack = HOMEBREW_CELLAR/oldname
    return false unless old_rack.directory?
    return false if old_rack.subdirs.empty?

    tap == Tab.for_keg(old_rack.subdirs.min).tap
  end

  # @private
  def print_tap_action(options = {})
    return unless tap?

    verb = options[:verb] || "Installing"
    ohai "#{verb} #{name} from #{tap}"
  end

  # True if this formula is provided by external Tap
  # @private
  def tap?
    return false unless tap

    !tap.core_tap?
  end

  # @private
  def possible_names
    [name, oldname, *aliases].compact
  end

  # @private
  def eligible_kegs_for_cleanup(quiet: false)
    eligible_for_cleanup = []
    if latest_version_installed?
      eligible_kegs = if head? && (head_prefix = latest_head_prefix)
        installed_kegs - [Keg.new(head_prefix)]
      else
        installed_kegs.select do |keg|
          tab = Tab.for_keg(keg)
          if version_scheme > tab.version_scheme
            true
          elsif version_scheme == tab.version_scheme
            pkg_version > keg.version
          else
            false
          end
        end
      end

      unless eligible_kegs.empty?
        eligible_kegs.each do |keg|
          if keg.linked?
            opoo "Skipping (old) #{keg} due to it being linked" unless quiet
          elsif pinned? && keg == Keg.new(@pin.path.resolved_path)
            opoo "Skipping (old) #{keg} due to it being pinned" unless quiet
          else
            eligible_for_cleanup << keg
          end
        end
      end
    elsif !installed_prefixes.empty? && !pinned?
      # If the cellar only has one version installed, don't complain
      # that we can't tell which one to keep. Don't complain at all if the
      # only installed version is a pinned formula.
      opoo "Skipping #{full_name}: most recent version #{pkg_version} not installed" unless quiet
    end
    eligible_for_cleanup
  end

  def self.hash_to_recursive_openstruct(hash)
    case hash
    when Hash
      StrictOpenStruct.new(hash.transform_values { |value| hash_to_recursive_openstruct(value) })
    when Array
      hash.map { |element| hash_to_recursive_openstruct(element) }
    else
      hash
    end
  end

  def self.allowed_missing_libraries
    Set.new
  end
end

# Wrapper for FormulaManifest for dependencies that defines the `#to_formula` method
# @api private
class DependencyManifest < FormulaManifest
  def to_formula
    self
  end
end
